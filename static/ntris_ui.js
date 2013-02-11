var ntris_ui = {
  initialize: function() {
    this._room_prototype = $('#room-prototype').html();
    $('.prototype').remove();

    $('#tabs').tabs();
    $('#tabs button').button().click(function(event) {
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

    $('#create-room-dialog').dialog($.extend(attrs, {
      buttons: {
        Submit: function() {
          var rules = {
            type: $('#game-type').val(),
          };
          if (rules.type == 'sprint') {
            rules.target = $('#point-target').slider('option', 'value');
          }
          ntris.submit_create_room(rules);
        },
        Cancel: function() {
          $('#create-room-dialog').dialog('close');
        },
      },
    }));
    $('#game-type').change(function() {
      if ($(this).val() == 'sprint') {
        $('#point-target-row').removeClass('hidden');
      } else {
        $('#point-target-row').addClass('hidden');
      }
    });
    $('#point-target').slider({
      min: 50,
      max: 250,
      step: 50,
      slide: function(event, ui) {
        $('#point-target-value').html(ui.value);
      },
    });

    $('#join-room-dialog').dialog($.extend(attrs, {}));
  },

  show_create_room_dialog: function(elt) {
    if (ntris.rooms.hasOwnProperty(name) && ntris.rooms[name].last_game) {
      var rules = ntris.rooms[name].last_game.rules;
      $('#game-type').val(rules.type);
      $('#game-type').trigger('change');
      if (rules.type == 'sprint') {
        $('#point-target').slider('option', 'value', rules.target);
        $('#point-target-value').html(rules.target);
      }
    } else {
      $('#game-type').val('sprint');
      $('#game-type').trigger('change');
      $('#point-target').slider('option', 'value', 100);
      $('#point-target-value').html(100);
    }

    this.show_dialog('create-room');
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
            ntris.submit_join_room(name, 'leave_room');
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
            ntris.submit_join_room(name, 'join_room');
          };
      }
      buttons.Spectate = function() {
          ntris.submit_join_room(name, 'spectate_on_room');
        };
    }
    buttons.Cancel = function() {
        $('#join-room-dialog').dialog('close');
      };
    $('#join-room-dialog').dialog('option', 'buttons', buttons);
    this.show_dialog('join-room');
  },

  show_leave_room_dialog: function(name, label) {
    $('#room-details').html('Are you sure you want to leave ' + label + '?');
    $('#room-membership').html('You will lose any games you are playing in this room.');
    $('#join-room-dialog').dialog('option', 'buttons', {
        Leave: function() {
          ntris.submit_join_room(name, 'leave_room');
        },
        Cancel: function() {
          $('#join-room-dialog').dialog('close');
        },
      });
    this.show_dialog('join-room');
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

  change_username: function(user, logged_in) {
    if (user.sid == ntris.user.sid) {
      if (logged_in) {
        $('#tabs').addClass('logged-in');
        $('#topbar').html('Status: logged in as ' + user.name);
      } else {
        $('#tabs').removeClass('logged-in');
        $('#topbar').html('Status: in guest mode as ' + user.name);
      }
    }
    $('.' + user.cls).html(user.name);
  },

  create_room_tab: function(room) {
    var lobby = (room.name == 'lobby');

    room_html = '<div class="room-tab" id="' + room.id + '">' + this._room_prototype + '</div>';
    li_html = '<li><a href="#' + room.id + '">' + room.label + '</a>';
    if (!lobby) {
      li_html += '<span id="leave-' + room.id + '" class="leave-icon ui-icon ui-icon-close"/>';
    }
    li_html += '</li>';
    $('#tablist').append(li_html);
    $('#tabs').append(room_html);
    if (!lobby) {
      $('#leave-' + room.id).click(function() {
        ntris.ui.show_leave_room_dialog(room.name, room.label);
      });
    }

    $('#' + room.id).find('.users').menu();
    if (lobby) {
      var elt = $('#' + room.id).find('.multiplayer').parent();
      elt.find('.header').html('Games:');
      $('#' + room.id).find('.multiplayer').remove();
      elt.append('<ul class="rooms"></ul>');
      $('#' + room.id).find('.rooms').menu();
    } else {
      $('#' + room.id + ' .boards').html('');
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

    $('#tabs').tabs('refresh');
    var num_tabs = $('.room-tab').length;
    $('#tabs').tabs('option', 'active', num_tabs - 1);
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

  update_game_state: function(room) {
    if (room.name == 'lobby') {
      $('#' + room.id + ' .multiplayer-rules').html('Create or join a game to play multiplayer!');
    } else {
      var rules = room.game.rules;
      var html = "<div>This game's rules:</div>";
      html += '<table class="rules-table">';
      html += '<tr><td class="rules-header">Game type:</td><td class="rule">' + rules.type + '</td></tr>';
      if (rules.type == 'sprint') {
        html += '<tr><td class="rules-header">Point target:</td><td class="rule">' + rules.target + '</td></tr>';
      }
      html += '</table>';

      if (room.game.started) {
        var time_left = Math.ceil(room.game.start_ts - Date.now()/1000);
        if (time_left > 0) {
          html += '<div>This game will start in:</div>';
          html += '<div class="countdown">' + time_left + '</div>';
        } else {
          html += '<div>This game has started!</div>';
        }
      }

      $('#' + room.id + ' .multiplayer-rules').html(html);
    }
  },

  update_rooms_list: function(name, label, members, game) {
    var cls = name + '-size';
    var size = members.length;

    if (size) {
      if (name == 'lobby') {
        $('#tablist a[href="#lobby-room"]').html('Lobby (' + size + ')');
        return;
      }

      var rules_summary = 'Battle';
      if (game.rules.type == 'sprint') {
        rules_summary = 'Sprint to ' + game.rules.target;
      }
      var room_title = label + ' (' + size + '/6)';
      var link_html = '<span class="bold">' + room_title + '</span> - ' + rules_summary;
      var new_li = '<li><a class="' + cls + '">' + link_html + '</a></li>';
      $('#lobby-room .rooms').each(function() {
        var link = $(this).find('.' + cls);
        if (link.length) {
          link.html(link_html);
        } else {
          $(this).append(new_li);
          $(this).menu('refresh');
        }
      });
      $('.' + cls).click(function() {
        var in_game = game && game.started;
        ntris.ui.show_join_room_dialog(name, label, size, in_game);
      });
      $('#tablist a[href="#' + name + '-room"]').html(room_title);
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
    html += '<div class="' + user.cls + ' header">' + user.name + '</div>';
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
