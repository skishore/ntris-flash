var ntris = {
  initialize: function() {
    this._room_prototype = $('#room-prototype').html() + '</div>';
    this.create_room('lobby', 'Lobby', true);

    $('#tabs').tabs();
    $('button').button().click(function(event) {
      event.preventDefault();
    });
  },

  create_room: function(id, name, skip_refresh) {
    roomHTML = '<div class="room-tab" id="' + id + '">' + this._room_prototype;
    $('#tablist').append('<li><a href="#' + id + '">' + name + '</a></li>');
    $('#tabs').append(roomHTML);

    var room = $('#' + id);
    room.find('.users').menu();
    room.find('.rooms').menu();

    if (!skip_refresh) {
      $('#tabs').tabs('refresh');
    }
  },

  launch_game: function(room, user, large) {
    var target = (large ? '.large-boards' : '.boards');
    var cls = target.slice(1, target.length - 1);
    var id = room + '-' + user + '-' + cls;

    var room = $('#' + room);
    var html = '<div class="' + cls + ' container">';
    html += '<div class="header">' + user + '</div>';
    html += '<div id="' + id + '" class="' + cls + '"></div></div>';
    room.find(target).append(html);

    var size = (large ? 16 : 8);
    ntris.create_board(id, size);
  },

  create_board: function(id, squareWidth) {
    var width = 14*squareWidth + Math.floor(7*squareWidth/2);
    var height = 26*squareWidth;
    swfobject.embedSWF('Board.swf', id, width, height, '10', null, {
      html_id: id,
      squareWidth: squareWidth,
    });
  },

  board_callback: function(id) {
    var board = $('#' + id)[0];
    board.start();
  },

  log_framerate: function(id, framerate) {
    //console.log('FPS (' + id + '): ' + framerate);
  },
};

var socket;
function socket_bridge_onload() {
  socket = new FlashSocket({
    on_connect: function() {
      console.log('Connected!');
      this.sendLine('<connection-made>')
    },
    on_data: function(data) {
      console.log(data);
    },
    on_close: function() {
      console.log('Lost connection.');
    },
    on_io_error: function(err) {
      console.log('IO error: ', err);
    },
    on_security_error: function(err) {
      console.log('Security error: ', err);
    },
  });
  socket.connect('127.0.0.1', '2045');
}
