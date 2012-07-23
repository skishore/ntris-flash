package {
  import Color;
  import Point;
  import RawBlockData;

  public class Block {
    public static const MAXBLOCKSIZE:int = 10;
    public static var NUMLEVELS:int;
    public static var NUMBLOCKTYPES:Vector.<int>;

    private static var blockData:Vector.<Block> = new Vector.<Block>();

    public var x:int;
    public var y:int;
    public var numSquares:int;
    public var squares:Vector.<Point>;
    public var height:int;
    public var rotates:Boolean;
    public var color:int;

    public function Block() {
      squares = new Vector.<Point>();
    }

    public static function loadBlockData():void {
      NUMLEVELS = RawBlockData.data[0][0];
      NUMBLOCKTYPES = Vector.<int>(RawBlockData.data[0].slice(1));
      if (NUMBLOCKTYPES.length != NUMLEVELS) {
        trace("Read an incorrect number of difficulty levels.");
      }
      NUMBLOCKTYPES.fixed = true;

      for (var i:int = 1; i < NUMBLOCKTYPES[NUMLEVELS - 1] + 1; i++) {
        var data:Array = RawBlockData.data[i];
        var block:Block = new Block();
        block.x = data[0];
        block.y = data[1];
        block.numSquares = data[2];
        if (data.length != 2*block.numSquares + 4) {
          trace("Block " + (i - 1) + " is incorrectly formatted.");
        }
        for (var j:int = 0; j < block.numSquares; j++) {
          block.squares.push(new Point(data[2*j + 3], data[2*j + 4]));
        }
        block.squares.fixed = true;

        block.color = Color.colorCode(data[2*block.numSquares + 3]);
        block.height = calculateBlockHeight(block);
        block.rotates = doesBlockRotate(block);
        blockData.push(block);
      }

      blockData.fixed = true;
    }

    private static function calculateBlockHeight(block:Block):int {
      var lowest:int = block.squares[0].y;
      var highest:int = block.squares[0].y;

      for (var i:int = 1; i < block.numSquares; i++) {
        if (block.squares[i].y < lowest) {
          lowest = block.squares[i].y;
        } else if (block.squares[i].y > highest) {
          highest = block.squares[i].y;
        }
      }

      return highest - lowest + 1;
    }

    private static function doesBlockRotate(block:Block):Boolean {
      var lowest:Point = new Point(block.squares[0].x, block.squares[0].y);
      var highest:Point = new Point(block.squares[0].x, block.squares[0].y);

      for (var i:int = 1; i < block.numSquares; i++) {
        if (block.squares[i].x < lowest.x) {
          lowest.x = block.squares[i].x;
        } else if (block.squares[i].x > highest.x) {
          highest.x = block.squares[i].x;
        }   

        if (block.squares[i].y < lowest.y) {
          lowest.y = block.squares[i].y;
        } else if (block.squares[i].y > highest.y) {
          highest.y = block.squares[i].y;
        }   
      }

      if (highest.x - lowest.x != highest.y - lowest.y) {
        return true;
      }

      var rotated:Point = new Point(0, 0); 
      for (i = 0; i < block.numSquares; i++) {
        rotated.x = lowest.x + highest.y - block.squares[i].y;  
        rotated.y = lowest.y + block.squares[i].x - lowest.x;
        var found:Boolean = false;
        for (var j:int = 0; j < block.numSquares; j++) {
          found = found ||
                  (rotated.x == block.squares[j].x &&
                   rotated.y == block.squares[j].y);
        }
        if (!found) {
          return true;
        }
      }

      return false;

    }
  }
}
