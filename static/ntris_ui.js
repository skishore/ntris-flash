var ntris_ui = {
  initialize: function() {
    this._room_prototype = $('#room-prototype').html() + '</div>';
    $('#tabs').tabs();
    $('button').button().click(function(event) {
      event.preventDefault();
    });
  },

  connected: function() {
    $('#topbar').removeClass('connecting');
    $('#topbar').addClass('connected');
    $('#topbar').html('Status: connected!');
  },

  create_room_tab: function(room, set_active) {
    var id = room + '-room';
    var name = room[0].toUpperCase() + room.slice(1);
    roomHTML = '<div class="room-tab" id="' + id + '">' + this._room_prototype;
    $('#tablist').append('<li><a href="#' + id + '">' + name + '</a></li>');
    $('#tabs').append(roomHTML);

    var room = $('#' + id);
    room.find('.users').menu();
    room.find('.rooms').menu();
    $('#tabs').tabs('refresh');

    if (set_active) {
      var num_tabs = $('#tabs').find('.room-tab').length;
      $('#tabs').tabs('option', 'active', num_tabs - 1);
    }
  },

  add_user_to_room: function(room, user) {
    var id = room + '-' + user + '-user';
    var html = '<li><a id="' + id + '" href="#">' + user + '</a></li>';
    var user_list = $('#' + room + '-room').find('.users');
    user_list.append(html);
    user_list.menu('refresh');
  },

  remove_user_from_room: function(room, user) {
    var id = room + '-' + user + '-user';
    var user_list = $('#' + room + '-room').find('.users');
    user_list.find('#' + id).remove();
    user_list.menu('refresh');
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
    this.create_board(id, size);
  },

  create_board: function(id, squareWidth) {
    var width = 14*squareWidth + Math.floor(7*squareWidth/2);
    var height = 26*squareWidth;
    swfobject.embedSWF('Board/Board.swf', id, width, height, '10', null, {
      html_id: id,
      squareWidth: squareWidth,
    });
  },

  disconnected: function() {
    $('#topbar').removeClass('connecting connected');
    $('#topbar').html('Status: disconnected.');
  },
};
