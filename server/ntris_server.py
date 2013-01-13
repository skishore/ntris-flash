import json
import md5
import MySQLdb
from random import randint

from twisted.internet import reactor
from twisted.internet.protocol import (
  Factory as ServerFactory,
  )
from twisted.protocols.basic import LineReceiver

port = 2045
policy_file_request = '<policy-file-request/>'
policy_file = '''
<cross-domain-policy>
  <allow-access-from domain="*" to-ports="%s" />
</cross-domain-policy>
''' % (port,)

password = open('../passwords/skishore@sql.mit.edu:skishore+ntris').read().strip()
conn = MySQLdb.connect('sql.mit.edu', 'skishore', password, 'skishore+ntris')
cursor = conn.cursor()

handlers = {}
def handler(f):
  handlers[f.__name__[3:]] = f

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
    if len(name) < 4 or len(name) > 32:
      error = 'Your username must be between 4 and 32 characters.'
    elif not name.isalnum():
      error = 'Your username must be alphanumeric.'
    elif len(password) < 4 or len(password) > 64:
      error = 'Your password must be between 8 and 64 characters.'
    else:
      password_hash = md5.new(password).hexdigest()
      try:
        cursor.execute('INSERT INTO user VALUES (%s, %s, %s)',
            (name, email, password_hash))
      except MySQLdb.IntegrityError:
        error = 'That username is already taken.'
    if error:
      return self.send_message('signup_error', error)
    self.name = name
    self.logged_in = True
    self.server.broadcast('change_username', self.to_dict())

  @handler
  def on_logout(self, data):
    if not self.logged_in:
      return
    self.name = data['name']
    self.logged_in = False
    self.server.broadcast('change_username', self.to_dict())

class ntrisRoom(object):
  def __init__(self, name):
    self.name = name
    self.members = {}

  def to_dict(self):
    return dict(
        room=self.name,
        members=[session.to_dict() for session in self.members.itervalues()],
      )

  def add_user(self, session):
    if session.sid not in self.members:
      self.members[session.sid] = session
      session.rooms[self.name] = self
      self.broadcast('room_update', self.to_dict())

  def remove_user(self, session):
    if session.sid in self.members:
      del self.members[session.sid]
      if self.name in session.rooms:
        del session.rooms[self.name]
      self.broadcast('room_update', self.to_dict())

  def broadcast(self, type, data):
    line = json.dumps([type, data])
    for session in self.members.itervalues():
      session.sendLine(line)

class ntrisServer(ServerFactory):
  def __init__(self):
    self.sessions = {}
    self.rooms = {'lobby': ntrisRoom('lobby')}

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
