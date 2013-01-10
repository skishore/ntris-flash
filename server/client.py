from twisted.internet import reactor
from twisted.internet.protocol import ClientFactory
from twisted.protocols.basic import LineReceiver

class RawInputClientProtocol(LineReceiver):
  def connectionMade(self):
    print "Connected! Sending 'asdf' and 'blah'"
    self.sendLine('asdf')
    self.sendLine('blah')

  def connectionLost(self, reason):
    print 'Lost connection.'

  def lineReceived(self, data):
    print 'Received: %s' % (data,)

class RawInputClient(ClientFactory):
  protocol = RawInputClientProtocol

if __name__ == '__main__':
  reactor.connectTCP('localhost', 2045, RawInputClient())
  reactor.run()
