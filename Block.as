package {
  import Board;
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
    public var angle:int;
    public var numSquares:int;
    public var squares:Vector.<Point>;
    public var height:int;
    public var rotates:Boolean;
    public var color:int;

    public var rowsFree:int;
    public var shoveaways:int;
    public var localStickFrames:int;
    public var globalStickFrames:int;

    // The default Block constructor does NOT initalize the squares Vector.
    // It should only be used when loading the block data; that is, it should
    // never be called outside this class.
    public function Block(i:int = -1) {
      if (i < 0) {
        return;
      }

      x = blockData[i].x;
      y = blockData[i].y;
      angle = 0;
      numSquares = blockData[i].numSquares;
      squares = Vector.<Point>(blockData[i].squares);
      height = blockData[i].height;
      rotates = blockData[i].rotates;
      color = blockData[i].color;

      shoveaways = Board.NUMSHOVEAWAYS;
      localStickFrames = Board.NUMLOCALSTICKFRAMES;
      globalStickFrames = Board.NUMGLOBALSTICKFRAMES;
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
        block.squares = new Vector.<Point>();
        for (var j:int = 0; j < block.numSquares; j++) {
          block.squares.push(new Point(data[2*j + 3], data[2*j + 4]));
        }
        block.squares.fixed = true;

        block.color = Color.colorCode(data[2*block.numSquares + 3]);
        block.height = calculateBlockHeight(block);
        block.rotates = doesBlockRotate(block);
        // Translate the block down until it is just visible.
        block.y += MAXBLOCKSIZE - block.height;
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
