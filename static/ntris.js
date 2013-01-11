var ntris = {
  socket: null,
  ui: ntris_ui,

  initialize: function() {
    this.ui.initialize();
    this.ui.create_room_tab('lobby', true);
    if (window.hasOwnProperty('after_initialize')) {
      window.after_initialize();
    }
  },

  board_callback: function(id) {
    var board = $('#' + id)[0];
    board.start();
  },

  log_framerate: function(id, framerate) {
    //console.log('FPS (' + id + '): ' + framerate);
  },

  connected: function() {
    this.ui.connected();
  },

  disconnected: function() {
    this.ui.disconnected();
  },
};

function socket_bridge_onload() {
  ntris.socket = new FlashSocket({
    on_connect: function() {
      ntris.connected()
      this.sendLine('<connection-made>')
    },
    on_data: function(data) {
      console.log(data);
    },
    on_close: function() {
      ntris.disconnected()
    },
    on_io_error: function(err) {
      console.log('IO error: ', err);
    },
    on_security_error: function(err) {
      console.log('Security error: ', err);
    },
  });
  ntris.socket.connect('127.0.0.1', '2045');
}

function after_initialize() {
}
