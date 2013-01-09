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
