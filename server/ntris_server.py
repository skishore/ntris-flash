from twisted.internet import reactor
from twisted.internet.protocol import (
  Factory as ServerFactory,
  )
from twisted.protocols.basic import LineReceiver

class ntrisSession(LineReceiver):
  def __init__(self, server, addr):
    self.server = server
    self.addr = addr

  def connectionMade(self):
    self.server.last_sid += 1
    self.sid = self.server.last_sid
    self.server.sessions[self.sid] = self
    print 'Connection by %s; session id %s' % (self.addr, self.sid)

  def connectionLost(self, reason):
    if self.sid in self.server.sessions:
      del self.server.sessions[self.sid]
    print 'Lost session %s' % (self.sid,)

  def lineReceived(self, line):
    #self.sendLine(line)
    print 'Received %s from session %s' % (line, self.sid)

class ntrisServer(ServerFactory):
  def __init__(self):
    self.last_sid = -1
    self.sessions = {}

  def buildProtocol(self, addr):
    return ntrisSession(self, addr)

if __name__ == '__main__':
  port = 2045
  print 'Server running at port %s' % (port,)
  reactor.listenTCP(port, ntrisServer())
  reactor.run()
