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

  launch_game: function(room, user, local) {
    var target = (local ? '.local-board' : '.other-boards');
    var cls = (local ? 'large-board' : 'board');
    var id = room + '-' + user + '-board';

    var room = $('#' + room);
    var html = '<div class="' + cls + ' container">';
    html += '<div class="header">' + user + '</div>';
    html += '<div id="' + id + '" class="' + cls + '"></div></div>';
    room.find(target).append(html);

    var size = (local ? 16 : 8);
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
