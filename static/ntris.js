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
    this.create_room('lobby');

    var sid = randint(0, 1 << 30);
    var name = 'guest' + randint(100000, 999999);
    this.user = this.create_user(sid, name);

    if (window.hasOwnProperty('after_initialize')) {
      window.after_initialize();
    }
  },

  create_room: function(name) {
    if (!this.rooms.hasOwnProperty(name)) {
      var room = {
        name: name,
        id: name + '-room',
        members: [],
        local_board: null,
        num_remote_boards: 0,
      };
      this.rooms[name] = room;
      var set_active = name == 'lobby';
      this.ui.create_room_tab(room, set_active);
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
    var index = room.members.indexOf(user);
    if (index != -1) {
      room.members.splice(index, 1);
      user.rooms.splice(user.rooms.indexOf(room), 1);
      this.ui.remove_user_from_room(user, room);
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
      board.json = undefined;
    }
  },

  on_connect: function() {
    this.connected = true;
    var line = JSON.stringify(['get_username', this.user]);
    this.socket.sendLine(line)
    this.ui.connected();
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
      for (i = 0; i < room.members.length; i++) {
        this.remove_user_from_room(users_to_remove[i], room);
      }
    }
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
