import json
import md5
import MySQLdb
from random import randint
import time

from twisted.internet import reactor
from twisted.internet.protocol import (
  Factory as ServerFactory,
  )
from twisted.protocols.basic import LineReceiver

port = 2045

# Flash socket policy files.
policy_file_request = '<policy-file-request/>'
policy_file = '''
<cross-domain-policy>
  <allow-access-from domain="*" to-ports="%s" />
</cross-domain-policy>
''' % (port,)

labels = [line.strip() for line in open('server/room_names.dat').readlines()]
room_names = dict((label.lower().replace(' ', '_'), label) for label in labels)

game_start_delay = 5

# Cursor open on the MySQL instance. Tolerates up to one OperaionalError
# per execute call, because our connection might be timed out by the server.
class CursorWithRetry(object):
  def __init__(self):
    self.password = open('../passwords/ntris@ideafutures').read().strip()
    self.cursor = self.new_cursor()

  def new_cursor(self):
    conn = MySQLdb.connect('198.101.212.47', 'ntris', self.password, 'ntris', connect_timeout=10)
    self.cursor = conn.cursor()
    return self.cursor

  def execute(self, sql, params=None):
    params = params or tuple()
    try:
      return self.cursor.execute(sql, params)
    except MySQLdb.OperationalError:
      cursor = self.new_cursor()
      return self.cursor.execute(sql, params)

  def commit(self):
    self.cursor.execute('commit')

  def fetchone(self):
    return self.cursor.fetchone()

  def fetchall(self):
    return self.cursor.fetchall()
cursor = CursorWithRetry()

# Decorator used to mark event handlers in ntrisSession.
handlers = {}
def handler(f):
  handlers[f.__name__[3:]] = f

# Class that holds a single session open for a client socket.
class ntrisSession(LineReceiver):
  delimiter = '\0'

  def __init__(self, server, addr):
    self.server = server
    self.addr = addr
    self.sid = None
    self.rooms = {}
    self.logged_in = False

  def to_dict(self):
    return dict(
        sid=self.sid,
        name=self.name,
        logged_in=self.logged_in,
      )

  def connectionMade(self):
    # Flash sockets aren't connected until they've sent a policy request
    # and received a policy file. Defer registering this session until then.
    pass

  def connectionLost(self, reason):
    if self.sid is not None:
      print 'Lost session %s' % (self.sid,)
      if self.sid in self.server.sessions:
        rooms = self.rooms.values()
        for room in rooms:
          room.remove_user(self)
        del self.server.sessions[self.sid]

  def lineReceived(self, line):
    if line == policy_file_request:
      self.sendLine(policy_file)
      return
    (type, data) = json.loads(line)
    if type == 'get_username' and self.sid is None:
      self.create_user(data['sid'], data['name'])
    elif type in handlers:
      handlers[type](self, data)
    elif self.sid is not None:
      data.update(self.to_dict())
      self.rooms[data['room']].broadcast(type, data)

  def send_message(self, type, data):
    self.sendLine(json.dumps([type, data]))

  def create_user(self, sid, name):
    print 'Connection by %s; (sid %s, address %s)' % (name, sid, self.addr)
    if sid in self.server.sessions:
      print 'Duplicate connection! Closing socket.'
      self.transport.loseConnection()
      return
    self.sid = sid
    self.name = name
    self.server.sessions[self.sid] = self
    self.server.rooms['lobby'].add_user(self)
    for room in self.server.rooms.itervalues():
      if room.name != 'lobby':
        self.send_message('room_update', room.to_dict())

  @handler
  def on_login(self, data):
    (name, password) = (data['name'], data['password'])
    password_hash = md5.new(password).hexdigest()
    count = cursor.execute('SELECT password_hash FROM user WHERE name=%s', (name,))
    if not count:
      return self.send_message('login_error', 'That username does not exist.')
    real_hash = cursor.fetchone()[0]
    if password_hash != real_hash:
      return self.send_message('login_error', 'Incorrect password.')
    self.name = name
    self.logged_in = True
    self.server.broadcast('change_username', self.to_dict())

  @handler
  def on_signup(self, data):
    if self.logged_in:
      return
    (name, email, password) = (data['name'], data['email'], data['password'])
    error = None
    if len(name) < 4 or len(name) > 16:
      error = 'Your username must be between 4 and 16 characters.'
    elif not name.isalnum():
      error = 'Your username must be alphanumeric.'
    elif len(email) > 64:
      error = 'Your email must less than 64 characters.'
    elif len(password) < 4 or len(password) > 256:
      error = 'Your password must be between 4 and 256 characters.'
    else:
      password_hash = md5.new(password).hexdigest()
      try:
        cursor.execute('INSERT INTO user VALUES (%s, %s, %s)',
            (name, email, password_hash))
        cursor.commit()
      except MySQLdb.IntegrityError:
        error = 'That username is already taken.'
    if error:
      return self.send_message('signup_error', error)
    self.name = name
    self.logged_in = True
    self.server.broadcast('change_username', self.to_dict())

  @handler
  def on_logout(self, name):
    if not self.logged_in:
      return
    self.name = name
    self.logged_in = False
    self.server.broadcast('change_username', self.to_dict())

  @handler
  def on_create_room(self, rules):
    unused_names = [name for name in room_names if name not in self.server.rooms]
    if not unused_names:
      return self.send_message('create_room_error', 'The server ran out of room names!')
    i = randint(0, len(unused_names) - 1)
    (name, label) = (unused_names[i], room_names[unused_names[i]])
    self.send_message('join_room', dict(
        name=name,
        label=label,
      ))
    self.server.rooms[name] = ntrisRoom(self.server, name, label)
    self.server.rooms[name].game = ntrisGame(self, rules)
    self.server.rooms[name].add_user(self)

  @handler
  def on_join_room(self, name):
    if name in self.rooms:
      return self.send_message('join_room_error', 'You are already a member of that room.')
    elif len(self.rooms) >= 6:
      return self.send_message('join_room_error', 'You cannot join more than 6 rooms.')
    elif name not in self.server.rooms:
      return self.send_message('join_room_error', 'That room no longer exists.')
    room = self.server.rooms[name]
    if len(room.members) >= 6:
      return self.send_message('join_room_error', 'That room is now full.')
    self.send_message('join_room', dict(
        name=room.name,
        label=room.label,
      ))
    room.add_user(self)

  @handler
  def on_spectate_on_room(self, name):
    pass

  @handler
  def on_leave_room(self, name):
    if name == 'lobby':
      return self.send_message('join_room_error', "You can't leave the lobby!")
    self.send_message('leave_room', name)
    if name in self.rooms:
      self.rooms[name].remove_user(self)

# Class that stores data about the rules and status of a multiplayer game.
class ntrisGame(object):
  def __init__(self, session, rules):
    self.rules = rules
    self.started = False
    self.start_ts = 0

  def to_dict(self):
    return dict(
        rules=self.rules,
        started=self.started,
        start_ts=self.start_ts,
      )

  def start(self):
    self.started = True
    self.start_ts = int(time.time()) + game_start_delay

# Class that stores data about the users in a given room.
class ntrisRoom(object):
  def __init__(self, server, name, label):
    self.server = server
    self.name = name
    self.label = label
    self.members = {}
    self.game = None

  def to_dict(self):
    return dict(
        room=self.name,
        label=self.label,
        members=[session.to_dict() for session in self.members.itervalues()],
        game=(self.game.to_dict() if self.game else None),
      )

  def add_user(self, session):
    if session.sid not in self.members:
      self.members[session.sid] = session
      session.rooms[self.name] = self
      self.server.broadcast('room_update', self.to_dict())

  def remove_user(self, session):
    if session.sid in self.members:
      del self.members[session.sid]
      if self.name in session.rooms:
        del session.rooms[self.name]
      self.server.broadcast('room_update', self.to_dict())
      if self.name != 'lobby' and not len(self.members):
        del self.server.rooms[self.name]

  def broadcast(self, type, data):
    line = json.dumps([type, data])
    for session in self.members.itervalues():
      session.sendLine(line)

# The server itself, which tracks a list of sessions and rooms.
class ntrisServer(ServerFactory):
  def __init__(self):
    self.sessions = {}
    self.rooms = {'lobby': ntrisRoom(self, 'lobby', 'Lobby')}

  def buildProtocol(self, addr):
    return ntrisSession(self, addr)

  def broadcast(self, type, data):
    line = json.dumps([type, data])
    for session in self.sessions.itervalues():
      session.sendLine(line)

if __name__ == '__main__':
  print 'Server running at port %s' % (port,)
  reactor.listenTCP(port, ntrisServer())
  reactor.run()
