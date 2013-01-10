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

  def connectionMade(self):
    # Flash sockets aren't connected until they've sent a policy request
    # and received a policy file. Defer registering this session until then.
    pass

  def connectionLost(self, reason):
    if self.sid is not None:
      print 'Lost session %s' % (self.sid,)
      if self.sid in self.server.sessions:
        del self.server.sessions[self.sid]

  def lineReceived(self, line):
    if line == POLICY_FILE_REQUEST:
      self.sendLine(POLICY_FILE)
    elif line == CONNECTION_MADE and self.sid is None:
      self.server.last_sid += 1
      self.sid = self.server.last_sid
      print 'Connection by %s; session id %s' % (self.addr, self.sid)
      self.server.sessions[self.sid] = self
    elif self.sid is not None:
      print "Received '%s' from session %s" % (line, self.sid)
      self.sendLine('Acknowledged: ' + line)

class ntrisServer(ServerFactory):
  def __init__(self):
    self.last_sid = -1
    self.sessions = {}

  def buildProtocol(self, addr):
    return ntrisSession(self, addr)

if __name__ == '__main__':
  print 'Server running at port %s' % (PORT,)
  reactor.listenTCP(PORT, ntrisServer())
  reactor.run()
