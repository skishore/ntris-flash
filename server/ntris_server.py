import json
from random import randint

from twisted.internet import reactor
from twisted.internet.protocol import (
  Factory as ServerFactory,
  )
from twisted.protocols.basic import LineReceiver

PORT = 2045
POLICY_FILE_REQUEST = '<policy-file-request/>'
POLICY_FILE = '''
<cross-domain-policy>
  <allow-access-from domain="*" to-ports="%s" />
</cross-domain-policy>
''' % (PORT,)
CONNECTION_MADE = '<connection-made>'

class ntrisSession(LineReceiver):
  delimiter = '\0'

  def __init__(self, server, addr):
    self.server = server
    self.addr = addr
    self.sid = None
    self.rooms = {}

  def to_dict(self):
    return dict(
        sid=self.sid,
        name=self.name,
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
    if line == POLICY_FILE_REQUEST:
      self.sendLine(POLICY_FILE)
      return
    (type, data) = json.loads(line)
    if type == 'get_username' and self.sid is None:
      self.create_user(data['sid'], data['name'])
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
  print 'Server running at port %s' % (PORT,)
  reactor.listenTCP(PORT, ntrisServer())
  reactor.run()
