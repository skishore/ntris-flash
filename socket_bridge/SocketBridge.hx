import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.events.ProgressEvent;
import flash.external.ExternalInterface;
import flash.net.Socket;
import flash.utils.ByteArray;

class SocketBridge {
    public static var sockets:Hash<Socket> = new Hash();

    public static function CAN_I_HAS_SOCKET() {return true;}

    public static function handle_connect(id:String, event) {
        ExternalInterface.call("(function(id){ var inst = window.FlashSocket._instances[id]; if (inst.on_connect) inst.on_connect();})", id);
    }

    public static function handle_close(id:String, event) {
        sockets.remove(id);
        ExternalInterface.call("(function(id){ var inst = window.FlashSocket._instances[id]; if (inst.on_close) inst.on_close();})", id);
    }

    public static function handle_io_error(id:String, event) {
        ExternalInterface.call("(function(id, err){ var inst = window.FlashSocket._instances[id]; if (inst.on_io_error) inst.on_io_error(err);})", id, event.text);
    }

    public static function handle_security_error(id:String, event) {
        ExternalInterface.call("(function(id, err){ var inst = window.FlashSocket._instances[id]; if (inst.on_security_error) inst.on_security_error(err);})", id, event.text);
    }

    public static function handle_data(id:String, event) {
        var socket:Socket = sockets.get(id);
        if (socket != null)  {
            var bytes:ByteArray = new ByteArray();
            socket.readBytes(bytes, 0, socket.bytesAvailable);
            var messages = bytes.toString().split("\x00");
            for (i in 0...(messages.length - 1)) {
              ExternalInterface.call("(function(id, data){ var inst = window.FlashSocket._instances[id]; if (inst.on_data) inst.on_data(data);})", id, messages[i]);
            }
            // This is the library's old code, which misses packets that are sent in quick succession.
            // (If there are multiple packets in the socket's buffer, readUTFBytes will only read the first.)
            //var msg = socket.readUTFBytes(socket.bytesAvailable);
            //ExternalInterface.call("(function(id, data){ var inst = window.FlashSocket._instances[id]; if (inst.on_data) inst.on_data(data);})", id, msg);
        }
    }

    public static function connect(instance_id:String, host:String, port:Int) {
        var socket:Socket = sockets.get(instance_id);
        if (socket != null)  {
            socket.connect(host, port);
        } else {
            socket = new Socket(host, port);
            sockets.set(instance_id, socket);

            socket.addEventListener(Event.CONNECT,
                function(e):Void { handle_connect(instance_id, e); }
            );

            socket.addEventListener(Event.CLOSE,
                function(e):Void { handle_close(instance_id, e); }
            );

            socket.addEventListener(IOErrorEvent.IO_ERROR,
                function(e):Void { handle_io_error(instance_id, e); }
            );

            socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR,
                function(e):Void { handle_security_error(instance_id, e); }
            );

            socket.addEventListener(ProgressEvent.SOCKET_DATA,
                function(e):Void { handle_data(instance_id, e); }
            );
        }
    }

    public static function close(instance_id:String) {
        var socket = sockets.get(instance_id);
        if (socket != null) {
            if (socket.connected) {
                socket.close();
                sockets.remove(instance_id);
            }
        }
    }

    public static function write(instance_id:String, msg) {
        var socket = sockets.get(instance_id);
        if (socket != null) {
            if (socket.connected) {
                socket.writeUTFBytes(msg);
                socket.flush();
            }
        }
    }

    public static function main() {
        ExternalInterface.addCallback("connect", connect);
        ExternalInterface.addCallback("close", close);
        ExternalInterface.addCallback("write", write);
        ExternalInterface.addCallback("CAN_I_HAS_SOCKET", CAN_I_HAS_SOCKET);
        ExternalInterface.call([
        "(function(){",
            "if (window.FlashSocket) return;",
            "var Class = function(properties){",
                "var cls = function(event_handlers){ ",
                    "for (var p in event_handlers) {",
                        "if (event_handlers.hasOwnProperty(p)) {",
                            "this[p] = event_handlers[p];",
                        "}",
                    "}",
                    "console.log(this);return this.init.apply(this);",
                "};",
                "cls.prototype = properties;",
                "cls.constructor = arguments.callee;",
                "return cls;",
            "};",
            "window.FlashSocket = new Class({",
                "init: function(){",
                    "this._instance = ''+window.FlashSocket._instances.length;",
                    "window.FlashSocket._instances.push(this);",
                "},",
                "connect: function(host, port) {",
                    "window.FlashSocket._bridge.connect(this._instance, host, port);",
                "},",
                "write: function(data){ ",
                    "window.FlashSocket._bridge.write(this._instance, data);",
                "},",
                "sendLine: function(data){ ",
                    "window.FlashSocket._bridge.write(this._instance, data + '\\0');",
                "},",
                "close: function(){ ",
                    "window.FlashSocket._instances[this._instance] = null;",
                    "window.FlashSocket._bridge.close(this._instance );",
                "},",
            "});",
            "window.FlashSocket._instances = [];",
            "var f = function(tag){",
                "var elems = document.getElementsByTagName(tag);",
                "for (var i=0; i<elems.length; i++) if (elems[i].CAN_I_HAS_SOCKET) return elems[i];",
            "};",
            "window.FlashSocket._bridge = f('embed') || f('object');",
            "if (window.hasOwnProperty('socket_bridge_onload')) {",
            "  socket_bridge_onload();",
            "}",
        "})"].join(''));
    }
}
