var ntris_ui = {
  initialize: function() {
    this._room_prototype = $('#room-prototype').html() + '</div>';
    $('#tabs').tabs();
    $('button').button().click(function(event) {
      event.preventDefault();
    });

    var attrs = {
      autoOpen: false,
      resizable: false,
      modal: true,
      width: 400,
    };

    function submit_login() {
      ntris.login($('#login-username').val(), $('#login-password').val());
    };
    $('#login-dialog').dialog($.extend(attrs, {
     buttons: {
        Submit: submit_login,
        Cancel: function() {
          $('#login-dialog').dialog('close');
        },
      },
    }));
    $('#login-password').keydown(function(e) {
      if (e.keyCode == 13) submit_login();
    });

    function submit_signup() {
      ntris.signup($('#signup-username').val(), $('#signup-email').val(),
                   $('#signup-password').val(), $('#retype-password').val());
    };
    $('#signup-dialog').dialog($.extend(attrs, {
     buttons: {
        Submit: submit_signup,
        Cancel: function() {
          $('#signup-dialog').dialog('close');
        },
      },
    }));
    $('#retype-password').keydown(function(e) {
      if (e.keyCode == 13) submit_signup();
    });
  },

  show_login_dialog: function() {
    this.set_login_error('');
    $('#login-dialog').find('input').val('');
    $('#login-dialog').dialog('open');
  },

  show_signup_dialog: function() {
    this.set_signup_error('');
    $('#signup-dialog').find('input').val('');
    $('#signup-dialog').dialog('open');
  },

  set_login_error: function(error) {
    $('#login-dialog').find('.error').html(error);
  },

  set_signup_error: function(error) {
    $('#signup-dialog').find('.error').html(error);
  },

  close_dialogs: function() {
    $('#login-dialog').dialog('close');
    $('#signup-dialog').dialog('close');
  },

  connected: function() {
    $('#topbar').removeClass('connecting');
    $('#topbar').addClass('connected');
    $('#topbar').html('Status: in guest mode as ' + ntris.user.name);
  },

  change_username: function(name, in_guest_mode) {
    if (in_guest_mode) {
      $('#topbar').html('Status: in guest mode as ' + name);
    } else {
      $('#topbar').html('Status: logged in as ' + name);
    }
  },

  create_room_tab: function(room, set_active) {
    var label = room.name[0].toUpperCase() + room.name.slice(1);
    roomHTML = '<div class="room-tab" id="' + room.id + '">' + this._room_prototype;
    $('#tablist').append('<li><a href="#' + room.id + '">' + label + '</a></li>');
    $('#tabs').append(roomHTML);

    $('#' + room.id).find('.users').menu();
    $('#' + room.id).find('.rooms').menu();
    $('#tabs').tabs('refresh');

    if (set_active) {
      var num_tabs = $('#tabs').find('.room-tab').length;
      $('#tabs').tabs('option', 'active', num_tabs - 1);
    }

    $('#' + room.id).find('.chat').keydown(function(e) {
      if (e.keyCode == 13) {
        var message = this.value;
        if (message) {
          this.value = '';
          ntris.send_chat_message(room, message);
        }
      }
    });
  },

  current_room_name: function() {
    var room_tab = $('.room-tab')[$('#tabs').tabs('option', 'active')];
    return room_tab.id.substr(0, room_tab.id.length - 5);
  },

  add_user_to_room: function(user, room) {
    var html = '<li><a class="' + user.cls + '" href="#">' + user.name + '</a></li>';
    var user_list = $('#' + room.id).find('.users');
    user_list.append(html);
    user_list.menu('refresh');
  },

  change_username_in_room: function(user, room) {
    $('#' + room.id).find('.' + user.cls).html(user.name);
  },

  remove_user_from_room: function(user, room) {
    var user_list = $('#' + room.id).find('.users');
    user_list.find('.' + user.cls).remove();
    user_list.menu('refresh');
  },

  chat: function(room, user, message) {
    var html = ('<div class="chat-message"><span class="chat-name">'
        + user.name + ':</span> ' + message + '</div>');
    var elt = $('#' + room.id).find('.chatbox');
    var at_bottom = this.at_bottom(elt);
    elt.append(html);
    if (at_bottom) {
      this.scroll_to_bottom(elt);
    }
  },

  create_board: function(room, user, local) {
    var target = (local ? '.large-boards' : '.boards');
    var cls = target.slice(1, target.length - 1);
    var id = room.id + '-' + user.cls + '-board';

    var html = '<div class="' + cls + ' container">';
    html += '<div class="header">' + user.name + '</div>';
    html += '<div id="' + id + '" class="' + cls + '"></div></div>';
    $('#' + room.id).find(target).append(html);

    var size = (local ? 16 : 8);
    this.create_board_on_div(id, size, local);
  },

  create_board_on_div: function(id, squareWidth, local) {
    local = (local ? 'true' : 'false');
    var width = 14*squareWidth + Math.floor(7*squareWidth/2);
    var height = 26*squareWidth;
    swfobject.embedSWF('Board/Board.swf', id, width, height, '11', null, {
      html_id: id,
      local: local,
      squareWidth: squareWidth,
    });
  },

  drop_board: function(board) {
    $(board.swf.parentElement).remove();
  },

  disconnected: function() {
    $('#topbar').removeClass('connecting connected');
    $('#topbar').html('Status: disconnected.');
  },

  at_bottom: function(elt) {
    return elt.scrollTop() + elt.innerHeight() == elt[0].scrollHeight;
  },

  scroll_to_bottom: function(elt) {
    elt.scrollTop(elt[0].scrollHeight);
  },
};
