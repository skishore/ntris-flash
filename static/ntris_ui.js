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
      ntris.submit_login($('#login-username').val(), $('#login-password').val());
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
      if (e.keyCode == 13) {
        submit_login();
        e.preventDefault();
      }
    });

    function submit_signup() {
      ntris.submit_signup($('#signup-username').val(), $('#signup-email').val(),
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
      if (e.keyCode == 13) {
        submit_signup();
        e.preventDefault();
      }
    });

    function submit_create_room() {
      ntris.submit_create_room($('#create-room-name').val());
    };
    $('#create-room-dialog').dialog($.extend(attrs, {
     buttons: {
        Submit: submit_create_room,
        Cancel: function() {
          $('#create-room-dialog').dialog('close');
        },
      },
    }));
    $('#create-room-name').keydown(function(e) {
      if (e.keyCode == 13) {
        submit_create_room();
        e.preventDefault();
      }
    });

    $('#join-room-dialog').dialog($.extend(attrs, {}));
  },

  show_join_room_dialog: function(name, label, size, in_game) {
    if (size == 1) {
      $('#room-details').html('There is 1 user in ' + label + '.');
    } else {
      $('#room-details').html('There are ' + size + ' users in ' + label + '.');
    }

    var buttons = {};
    if (ntris.rooms.hasOwnProperty(name)) {
      $('#room-membership').html('You are a member of this room.');
      buttons['Go to'] = function() {
          ntris.ui.change_rooms(name);
          $('#join-room-dialog').dialog('close');
        };
      if (name != 'lobby') {
        buttons.Leave = function() {
            ntris.submit_join_room($('#join-room-name').val(), 'leave_room');
          };
      }
    } else {
      if (in_game) {
        $('#room-membership').html('The players in this room are in a multiplayer game. ' +
                                   'You can spectate from the lobby.');
      } else if (size >= 6) {
        $('#room-membership').html('This room is full, but you can spectate from the lobby.');
      } else {
        $('#room-membership').html('You can join this room or spectate from the lobby.');
        buttons.Join = function() {
            ntris.submit_join_room($('#join-room-name').val(), 'join_room');
          };
      }
      buttons.Spectate = function() {
          ntris.submit_join_room($('#join-room-name').val(), 'spectate_on_room');
        };
    }
    buttons.Cancel = function() {
        $('#join-room-dialog').dialog('close');
      };
    $('#join-room-dialog').dialog('option', 'buttons', buttons);

    this.show_dialog('join-room');
    $('#join-room-name').val(name);
  },

  show_dialog: function(dialog) {
    this.set_dialog_error(dialog, '');
    $('#' + dialog + '-dialog').find('input').val('');
    $('#' + dialog + '-dialog').dialog('open');
  },

  set_dialog_error: function(dialog, error) {
    $('#' + dialog + '-dialog').find('.error').html(error);
  },

  close_dialogs: function() {
    $('.ui-dialog-content').dialog('close');
  },

  connected: function() {
    $('#topbar').removeClass('connecting');
    $('#topbar').addClass('connected');
    $('#topbar').html('Status: in guest mode as ' + ntris.user.name);
  },

  change_username: function(name, logged_in) {
    if (logged_in) {
      $('#tabs').addClass('logged-in');
      $('#topbar').html('Status: logged in as ' + name);
    } else {
      $('#tabs').removeClass('logged-in');
      $('#topbar').html('Status: in guest mode as ' + name);
    }
  },

  create_room_tab: function(room, set_active) {
    roomHTML = '<div class="room-tab" id="' + room.id + '">' + this._room_prototype;
    $('#tablist').append('<li><a href="#' + room.id + '">' + room.label + '</a></li>');
    $('#tabs').append(roomHTML);

    $('#' + room.id).find('.users').menu();
    // TODO: Links copied from the lobby do not have an onlick.
    // This is okay because the rooms div will be replaced by a game div
    // in other rooms, but they're broken for now.
    var rooms_list = $('#' + room.id).find('.rooms');
    var room_links = $('#lobby-room').find('.rooms').find('li');
    for (var i = 0; i < room_links.length; i++) {
      rooms_list.append('<li>' + $(room_links[i]).html() + '</li>');
    }
    rooms_list.menu();

    $('#' + room.id).find('.chat').keydown(function(e) {
      if (e.keyCode == 13) {
        var message = this.value;
        if (message) {
          this.value = '';
          ntris.send_chat_message(room, message);
        }
      }
    });

    $('#tabs').tabs('refresh');
    if (set_active) {
      var num_tabs = $('.room-tab').length;
      $('#tabs').tabs('option', 'active', num_tabs - 1);
    }
  },

  current_room_name: function() {
    var room_tab = $('.room-tab')[$('#tabs').tabs('option', 'active')];
    return room_tab.id.substr(0, room_tab.id.length - 5);
  },

  drop_room_tab: function(room) {
    var return_to_lobby = (this.current_room_name() == room.name);
    $($('#tablist a[href="#' + room.id + '"]').parent()).remove();
    $('#' + room.id).remove();
    $('#tabs').tabs('refresh');
    if (return_to_lobby) {
      $('#tabs').tabs('option', 'active', 0);
    }
  },

  change_rooms: function(name) {
    if (ntris.rooms.hasOwnProperty(name)) {
      var room = ntris.rooms[name];
      var room_tabs = $('.room-tab');
      for (var i = 0; i < room_tabs.length; i++) {
        if (room_tabs[i].id == room.id) {
          $('#tabs').tabs('option', 'active', i);
          return;
        }
      }
    }
  },

  update_room_sizes: function(name, label, size) {
    var cls = name + '-size';
    if (size) {
      var link_html = label + ' (' + size + (name == 'lobby' ? ')' : '/6)');
      var new_li = '<li><a class="' + cls + '">' + link_html + '</a></li>';
      $('.room-tab .rooms').each(function() {
        var link = $(this).find('.' + cls);
        if (link.length) {
          link.html(link_html);
        } else {
          $(this).append(new_li);
          $(this).menu('refresh');
        }
      });
      $('.' + cls).click(function() {
        ntris.ui.show_join_room_dialog(name, label, size);
      });
    } else {
      $($('.' + cls).parent()).remove();
    }
  },

  add_user_to_room: function(user, room) {
    var html = '<li><a class="' + user.cls + '" href="#">' + user.name + '</a></li>';
    var user_list = $('#' + room.id).find('.users');
    user_list.append(html);
    user_list.menu('refresh');
  },

  change_username_in_room: function(user, room) {
    $('#' + room.id).find('.' + user.cls).html(user.name);
    var local = (user === ntris.user);
    var board = null;
    if (local && room.local_board) {
      board = room.local_board;
    } else if (!local && room.remote_boards.hasOwnProperty(user.sid)) {
      board = room.remote_boards[user.sid];
    }
    if (board) {
      $('#' + board.id).siblings('.header').html(user.name);
    }
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
    this.close_dialogs();
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
