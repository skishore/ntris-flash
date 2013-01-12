function randint(a, b) {
  return Math.floor(a + (b - a)*Math.random());
};

var ntris = {
  ui: ntris_ui,

  user: null,
  users: {},
  rooms: {},

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
        local_game: null,
        remote_games: [],
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
    this.ui.create_game(room, this.user, true);
  },

  board_callback: function(id, local) {
    if (local) {
      var board = $('#' + id)[0];
      board.start();
    }
  },

  on_connect: function() {
    var line = JSON.stringify(['get_username', this.user]);
    this.socket.sendLine(line)
    this.ui.connected();
  },

  on_room_update: function(data) {
    var room = this.create_room(data.name);
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
  },

  on_chat: function(data) {
    if (this.rooms.hasOwnProperty(data.room)) {
      var room = this.rooms[data.room];
      var user = this.create_user(data.sid, data.name);
      this.ui.chat(room, user, data.message);
    }
  },

  on_disconnect: function() {
    this.ui.disconnected();
  },

  send_chat_message: function(room, message) {
    var line = JSON.stringify(['chat', {
      room: room.name,
      message: message,
    }]);
    this.socket.sendLine(line);
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
