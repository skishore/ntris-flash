function randint(a, b) {
  return Math.floor(a + (b - a)*Math.random());
};

var ntris = {
  ui: ntris_ui,

  connected: false,
  user: null,
  users: {},
  rooms: {},
  boards: {},

  initialize: function() {
    this.ui.initialize();
    this.create_room('lobby', 'Lobby');

    var sid = randint(0, 1 << 30);
    var name = 'guest' + randint(100000, 999999);
    this.user = this.create_user(sid, name);
    this.user.original_name = this.user.name;

    if (window.hasOwnProperty('after_initialize')) {
      window.after_initialize();
    }
  },

  submit_login: function(name, password) {
    if (this.connected) {
      if (!name) {
        this.ui.set_dialog_error('login', 'Enter your username.');
      } else if (!password) {
        this.ui.set_dialog_error('login', 'Enter your password.');
      } else {
        var line = JSON.stringify(['login', {
          name: name,
          password: password,
        }])
        this.socket.sendLine(line);
      }
    } else {
      this.ui.set_dialog_error('login', 'Not connected to the server.');
    }
  },

  submit_signup: function(name, email, password, retype) {
    if (this.connected) {
      if (!name || !password) {
        this.ui.set_dialog_error('signup', 'You must enter a username and password.');
      } else if (password != retype) {
        this.ui.set_dialog_error('signup', 'Your password entries do not match.');
      } else {
        var line = JSON.stringify(['signup', {
          name: name,
          email: email,
          password: password,
        }])
        this.socket.sendLine(line);
      }
    } else {
      this.ui.set_dialog_error('signup', 'Not connected to the server.');
    }
  },

  submit_create_room: function(label) {
    if (this.connected) {
      if (!label) {
        this.ui.set_dialog_error('create-room', 'Enter a name for your room.');
      } else {
        var line = JSON.stringify(['create_room', {
          label: label,
        }]);
        this.socket.sendLine(line);
      }
    } else {
      this.ui.set_dialog_error('create-room', 'Not connected to the server.');
    }
  },

  logout: function() {
    this.socket.sendLine(JSON.stringify(['logout', {
      name: this.user.original_name
    }]));
  },

  create_room: function(name, label) {
    if (!this.rooms.hasOwnProperty(name)) {
      var room = {
        name: name,
        id: name + '-room',
        label: label,
        members: [],
        local_board: null,
        num_remote_boards: 0,
      };
      this.rooms[name] = room;
      this.ui.create_room_tab(room, true);
    }
    return this.rooms[name];
  },

  create_user: function(sid, name) {
    if (!this.users.hasOwnProperty(sid)) {
      var user = {
        sid: sid,
        cls: sid + '-user',
        name: name,
        rooms: [],
      };
      this.users[sid] = user;
    }
    return this.users[sid];
  },

  create_board: function(room, user) {
    var id = room.id + '-' + user.cls + '-board';
    if (!this.boards.hasOwnProperty(id)) {
      var board = {
        id: id,
        initialized: false,
      };
      if (user === this.user) {
        room.local_board = board;
        this.ui.create_board(room, user, true);
      } else if (room.num_remote_boards < 6) {
        room.num_remote_boards++;
        this.ui.create_board(room, user);
      } else {
        // Too many remote boards in this room - cannot create another.
        return null;
      }
      this.boards[id] = board;
    }
    return this.boards[id];
  },

  add_user_to_room: function(user, room) {
    if (room.members.indexOf(user) == -1) {
      room.members.push(user);
      user.rooms.push(room);
      this.ui.add_user_to_room(user, room);
    }
  },

  remove_user_from_room: function(user, room) {
    if (user === this.user) {
      console.debug('Should never have to remove this user from a room!');
      return;
    }
    var index = room.members.indexOf(user);
    if (index != -1) {
      room.members.splice(index, 1);
      user.rooms.splice(user.rooms.indexOf(room), 1);
      this.drop_board_if_exists(user, room);
      this.ui.remove_user_from_room(user, room);
      if (!user.rooms.length) {
        delete this.users[user.sid];
      }
    }
  },

  drop_board_if_exists: function(user, room) {
    var id = room.id + '-' + user.cls + '-board';
    if (this.boards.hasOwnProperty(id)) {
      var board = this.boards[id];
      var local = (user === this.user);
      if (local) {
        room.local_board = null;
      } else {
        room.num_remote_boards--;
      }
      this.ui.drop_board(board);
      delete this.boards[board.id];
    }
  },

  play_singleplayer: function() {
    var room = this.rooms[this.ui.current_room_name()];
    this.create_board(room, this.user, true);
  },

  board_callback: function(id, local) {
    var board = this.boards[id];
    board.initialized = true;
    board.swf = $('#' + id)[0];
    if (local) {
      board.swf.start();
    } else if (board.json) {
      board.swf.deserialize(board.json);
      delete board.json;
    }
  },

  on_connect: function() {
    this.connected = true;
    var line = JSON.stringify(['get_username', this.user]);
    this.socket.sendLine(line)
    this.ui.connected();
  },

  on_login_error: function(error) {
    this.ui.set_dialog_error('login', error);
  },

  on_signup_error: function(error) {
    this.ui.set_dialog_error('signup', error);
  },

  on_create_room_error: function(error) {
    this.ui.set_dialog_error('create-room', error);
  },

  on_change_username: function(data) {
    if (data.sid == this.user.sid) {
      this.ui.close_dialogs();
      this.ui.change_username(data.name, data.logged_in);
    }

    var user = this.create_user(data.sid, data.name);
    if (user.name != data.name) {
      user.name = data.name;
      for (var i = 0; i < user.rooms.length; i++) {
        this.ui.change_username_in_room(user, user.rooms[i]);
      }
    }
  },

  on_join_room: function(data) {
    this.ui.close_dialogs();
    this.create_room(data.name, data.label);
  },

  on_room_update: function(data) {
    if (this.rooms.hasOwnProperty(data.room)) {
      var room = this.rooms[data.room];
      var sids = [];
      for (var i = 0; i < data.members.length; i++) {
        var user = this.create_user(data.members[i].sid, data.members[i].name);
        this.add_user_to_room(user, room);
        sids.push(data.members[i].sid);
      }
      var users_to_remove = [];
      for (i = 0; i < room.members.length; i++) {
        if (sids.indexOf(room.members[i].sid) == -1) {
          users_to_remove.push(room.members[i]);
        }
      }
      for (i = 0; i < users_to_remove.length; i++) {
        this.remove_user_from_room(users_to_remove[i], room);
      }
    }
    this.ui.update_room_sizes(data.room, data.label, data.members.length);
  },

  on_board_update: function(data) {
    if (this.rooms.hasOwnProperty(data.room) &&
        data.sid != this.user.sid) {
      var room = this.rooms[data.room];
      var user = this.create_user(data.sid, data.name);
      var board = this.create_board(room, user);
      if (board.initialized) {
        board.swf.deserialize(data.json);
      } else {
        board.json = data.json;
      }
    }
  },

  on_chat: function(data) {
    if (this.rooms.hasOwnProperty(data.room)) {
      var room = this.rooms[data.room];
      var user = this.create_user(data.sid, data.name);
      this.ui.chat(room, user, data.message);
    }
  },

  on_disconnect: function() {
    this.connected = false;
    this.ui.disconnected();
  },

  send_chat_message: function(room, message) {
    if (this.connected) {
      var line = JSON.stringify(['chat', {
        room: room.name,
        message: message,
      }]);
      this.socket.sendLine(line);
    }
  },

  send_board_update: function(id, json) {
    if (this.connected) {
      var room_name = id.split('-')[0];
      var line = JSON.stringify(['board_update', {
        room: room_name,
        json: json,
      }]);
      this.socket.sendLine(line);
    }
  },

  log_framerate: function(id, framerate) {
    //console.log('FPS (' + id + '): ' + framerate);
  },
};

function socket_bridge_onload() {
  ntris.socket = new FlashSocket({
    on_connect: function() {
      ntris.on_connect()
    },
    on_data: function(json) {
      var result = JSON.parse(json);
      var handler = 'on_' + result[0];
      if (ntris.hasOwnProperty(handler)) {
        ntris[handler](result[1]);
      } else {
        console.log('No ' + handler + ' handler:');
        console.log(result[1]);
      }
    },
    on_close: function() {
      ntris.on_disconnect()
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
