package {
  import flash.display.MovieClip;
  import flash.events.KeyboardEvent;
  import flash.events.TimerEvent;
  import flash.utils.Timer;
  import flash.utils.getTimer;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
  import flash.geom.Matrix;
  import flash.geom.Rectangle;
  import flash.text.TextField;

  import Block;
  import Color;
  import Key;
  import KeyRepeater;

  [SWF(width="367", height="546")]

  public class Board extends MovieClip {
    // Board size constants.
    private static const VISIBLEROWS:int = 24;
    private static const ROWS:int = (VISIBLEROWS + Block.MAXBLOCKSIZE - 1);
    private static const COLS:int = 12;

    // Screen size constants.
    private static const SQUAREWIDTH:int = 21;
    private static const BORDER:int = SQUAREWIDTH;
    private static const SIDEBOARD:int = 7*SQUAREWIDTH/2;
    private static const WIDTH:int = SQUAREWIDTH*COLS + SIDEBOARD + 2*BORDER;
    private static const HEIGHT:int = SQUAREWIDTH*VISIBLEROWS + 2*BORDER;

    // Game engine constants.
    private static const FRAMERATE:int = 60;
    private static const FRAMEDELAY:int = 1000/FRAMERATE;
    private static const MAXFRAME:int = 3628800;
    private static const PAUSE:int = 120;
    private static const REPEAT:int = 30;

    // Block movement constants, some of which are imported by Block.
    private static const GRAVITY:int = 60;
    public static const SHOVEAWAYS:int = 2;
    public static const LOCALSTICKFRAMES:int = 24;
    public static const GLOBALSTICKFRAMES:int = 120;

    // Block overlap codes, in order of priority.
    private static const LEFTEDGE:int = 0;
    private static const RIGHTEDGE:int = 1;
    private static const TOPEDGE:int = 2;
    private static const BOTTOMEDGE:int = 3;
    private static const OVERLAP:int = 4;
    private static const OK:int = 5;

    // Canvas bitmap data.
    private var xPos:int = SQUAREWIDTH;
    private var yPos:int = SQUAREWIDTH;
    private var canvasBD:BitmapData;
    private var canvasBitmap:Bitmap;

    // Timing variables.
    private var timer:Timer;
    private var beforeTime:int = 0;
    private var afterTime:int = 0;
    private var sleepTime:int = 0;
    private var numFrames:int = 0;
    private var lastSecond:int = 0;
    private var curFrame:int = 0;
    private var framerateText:TextField;

    // Board data structures.
    private var curBlock:Block;
    private var data:Vector.<Vector.<int>>;

    // Auxiliary board variables.
    private var repeater:KeyRepeater;
    private var keysFired:Vector.<int>;

    public function Board() {
      canvasBD = new BitmapData(WIDTH, HEIGHT, false, 0xffffff);
      canvasBitmap = new Bitmap(canvasBD);
      addChild(canvasBitmap);

      framerateText = new TextField();
      framerateText.x = BORDER + SQUAREWIDTH*COLS + SQUAREWIDTH/2;
      framerateText.y = BORDER;
      framerateText.textColor = 0xffffff;

      Block.loadBlockData();
      curBlock = null;

      data = new Vector.<Vector.<int>>();
      for (var i:int = 0; i < ROWS; i++) {
        data.push(new Vector.<int>());
        for (var j:int = 0; j < COLS; j++) {
          data[i].push(0x0);
        }
        data[i].fixed = true;
      }
      data.fixed = true;

      repeater = new KeyRepeater(PAUSE, REPEAT);
      stage.addEventListener(KeyboardEvent.KEY_DOWN, repeater.keyPressed);
      stage.addEventListener(KeyboardEvent.KEY_UP, repeater.keyReleased);
      keysFired = new Vector.<int>();

      timer = new Timer(FRAMEDELAY, 1);
      timer.addEventListener(TimerEvent.TIMER, gameLoop);
      timer.start();
    }

    private function gameLoop(e:TimerEvent):void {
      beforeTime = getTimer();
      var oversleepTime:int = (beforeTime - afterTime) - sleepTime;

      numFrames++;
      if (beforeTime > lastSecond + 1000) {
        var framesPerSecond:Number = 1000.0*numFrames/(beforeTime - lastSecond);
        framerateText.text = "FPS: " + framesPerSecond.toPrecision(4);
        numFrames = 0;
        lastSecond = beforeTime;
      }

      update();
      draw();

      afterTime = getTimer();
      sleepTime = FRAMEDELAY - (afterTime - beforeTime) - oversleepTime;
      if(sleepTime <= 0) {
        sleepTime = 0;
      }

      timer.reset();
      timer.delay = sleepTime;
      timer.start();

      e.updateAfterEvent();
    }

//-------------------------------------------------------------------------
// ntris game logic begins here!
//-------------------------------------------------------------------------
    private function update():void {
      curFrame = (curFrame + 1) % MAXFRAME;

      repeater.query(keysFired);

      if (curBlock == null) {
        curBlock = getNextBlock();
        return;
      } else {
        if (moveBlock(curBlock)) {
          curBlock = getNextBlock();
        }
      }
    }

    private function getNextBlock():Block {
      var block:Block = new Block(curFrame % 29);
      block.x += COLS/2;
      block.rowsFree = calculateRowsFree(block);
      return block;
    }

    // Returns true if this block was placed.
    private function moveBlock(block:Block):Boolean {
      var shift:int = 0;
      var drop:Boolean = curFrame % GRAVITY == 0;
      var turn:int = 0;
      var moved:Boolean = false;

      for (var i:int = 0; i < keysFired.length; i++) {
        if (keysFired[i] == Key.RIGHT) {
          shift++;
        } else if (keysFired[i] == Key.LEFT) {
          shift--;
        } else if (keysFired[i] == Key.DOWN) {
          drop = true;
        } else if (keysFired[i] == Key.UP) {
          turn = 1;
        } else if (keysFired[i] == Key.SPACE) {
          block.y += block.rowsFree;
          placeBlock(block);
          return true;
        }
      }

      if (shift != 0) {
        block.x += shift;
        if (checkBlock(block) == OK) {
          moved = true;
        } else {
          block.x -= shift;
        }
      }

      if (turn != 0) {
        block.angle = (block.angle + turn + 4) % 4;
        var trans:Point = new Point();
        while (checkBlock(block) == LEFTEDGE) {
          block.x++;
          trans.x++;
        }
        while (checkBlock(block) == RIGHTEDGE) {
          block.x--;
          trans.x--;
        }
        while (checkBlock(block) == TOPEDGE) {
          block.y++;
          trans.y++;
        }
        if (checkBlock(block) == OK) {
          moved = true;
        } else if (block.shoveaways > 0 && shoveaway(block, shift)) {
          block.shoveaways--;
          moved = true;
        } else {
          block.x -= trans.x;
          block.y -= trans.y;
          block.angle = (block.angle - turn + 4) % 4;
        }
      }

      if (moved) {
        block.rowsFree = calculateRowsFree(block);
        block.localStickFrames = LOCALSTICKFRAMES;
      }

      if (block.rowsFree > 0) {
        block.localStickFrames = LOCALSTICKFRAMES;
        block.globalStickFrames = GLOBALSTICKFRAMES;
        if (drop) {
          block.y++;
          block.rowsFree--;
        }
      } else {
        block.globalStickFrames--;
        if (!moved) {
          block.localStickFrames--;
        }
        if (block.localStickFrames <= 0 || block.globalStickFrames <= 0) {
          placeBlock(block);
          return true;
        }
      }

      return false;
    }

    // Tries to shove the block away from an obstructing square or from the lower
    // edge. Returns true on success. Leaves the block unchanged on failure.
    private function shoveaway(block:Block, hint:int = 0):Boolean {
      // In the absence of a hint, prefer to shove left over shoving right.
      hint = (hint > 0 ? 1 : -1);

      for (var i:int = 0; i < 4; i++) {
        for (var j:int = 0; j < 3; j++) {
          if (checkBlock(block) == OK) {
            return true;
          }
          block.x += (j == 1 ? -2*hint : hint);
        }
        if (i == 0) {
          block.y++;
        } else if (i == -1) {
          block.y -= 2;
        } else {
          block.y--;
        }
      }

      block.y += 3;
      return false;
    }

    private function placeBlock(block:Block):void {
      var point:Point = new Point();

      for (var i:int = 0; i < block.numSquares; i++) {
        if (block.angle % 2 == 0) {
          point.x = block.x + (1 - (block.angle % 4))*block.squares[i].x;
          point.y = block.y + (1 - (block.angle % 4))*block.squares[i].y;
        } else {
          point.x = block.x - (2 - (block.angle % 4))*block.squares[i].y;
          point.y = block.y + (2 - (block.angle % 4))*block.squares[i].x;
        }
        data[point.y][point.x] = block.color;
      }

      removeRows();
    }

    private function removeRows():int {
      var numRowsCleared:int = 0;
      var isRowFull:Boolean;

      for (var i:int = ROWS - 1; i >= 0; i--) {
        isRowFull = true;
        for (var j:int = 0; j < COLS; j++) {
          if (data[i][j] == Color.BLACK) {
            isRowFull = false;
          }
        }

        if (isRowFull) {
          for (j = 0; j < COLS; j++) {
            data[i][j] = Color.BLACK;
          }
          numRowsCleared++;
        } else if (numRowsCleared > 0) {
          for (j = 0; j < COLS; j++) {
            data[i + numRowsCleared][j] = data[i][j];
            data[i][j] = Color.BLACK;
          }
        }
      }

      return numRowsCleared;
    }

    private function calculateRowsFree(block:Block):int {
      var rowsFree:int = 0;
      while (checkBlock(block) == OK) {
        rowsFree++;
        block.y++;
      }
      block.y -= rowsFree;
      return rowsFree - 1;
    }

    private function checkBlock(block:Block):int {
      var point:Point = new Point();
      var status:int = OK;

      for (var i:int = 0; i < block.numSquares; i++) {
        if (block.angle % 2 == 0) {
          point.x = block.x + (1 - (block.angle % 4))*block.squares[i].x;
          point.y = block.y + (1 - (block.angle % 4))*block.squares[i].y;
        } else {
          point.x = block.x - (2 - (block.angle % 4))*block.squares[i].y;
          point.y = block.y + (2 - (block.angle % 4))*block.squares[i].x;
        }

        // Check for obstructions in order of priority.
        if (point.x < 0) {
          status = Math.min(LEFTEDGE, status);
        } else if (point.x >= COLS) {
          status = Math.min(RIGHTEDGE, status);
        } else if (point.y < 0) {
          status = Math.min(TOPEDGE, status);
        } else if (point.y >= ROWS) {
          status = Math.min(BOTTOMEDGE, status);
        } else if (data[point.y][point.x] != Color.BLACK) {
          status = Math.min(OVERLAP, status);
        }
      }

      return status;
    }

//-------------------------------------------------------------------------
// Drawing code begins here!
//-------------------------------------------------------------------------
    private function draw():void {
      canvasBD.lock();

      // Clear the screen and draw the border and grid lines.
      fillRect(canvasBD, 0, 0, WIDTH, HEIGHT, Color.BLACK);
      drawRect(canvasBD, BORDER/2 - 1, BORDER/2 - 1,
               WIDTH - BORDER + 2, HEIGHT - BORDER + 2, Color.GREEN);
      drawRect(canvasBD, BORDER/2, BORDER/2,
               WIDTH - BORDER, HEIGHT - BORDER, Color.GREEN);
      var lineColor:int = Color.lighten(Color.BLACK);
      for (var i:int = 0; i < VISIBLEROWS; i++) {
        drawHLine(canvasBD, xPos, yPos + SQUAREWIDTH*i,
                  SQUAREWIDTH*COLS, lineColor);
        drawHLine(canvasBD, xPos, yPos + SQUAREWIDTH*(i + 1) - 1,
                  SQUAREWIDTH*COLS, lineColor);
      }
      for (i = 0; i < COLS; i++) {
        drawVLine(canvasBD, xPos + SQUAREWIDTH*i, yPos,
                  SQUAREWIDTH*VISIBLEROWS, lineColor);
        drawVLine(canvasBD, xPos + SQUAREWIDTH*(i + 1) - 1, yPos,
                  SQUAREWIDTH*VISIBLEROWS, lineColor);
      }

      // Draw the occupied squares on the board and the current block.
      for (i = ROWS - VISIBLEROWS; i < ROWS; i++) {
        for (var j:int = 0; j < COLS; j++) {
          drawBoardSquare(canvasBD, i, j, data[i][j]);
        }
      }
      drawBlock(canvasBD, curBlock, true);
      drawBlock(canvasBD, curBlock);

      drawTextField(canvasBD, framerateText);

      canvasBD.unlock();
    }

    private function drawBlock(
        bd:BitmapData, block:Block, shadow:Boolean=false):void {
      if (block == null) {
        return;
      }

      var point:Point = new Point();
      for (var i:int = 0; i < block.numSquares; i++) {
        if (block.angle % 2 == 0) {
          point.x = block.x + (1 - (block.angle % 4))*block.squares[i].x;
          point.y = block.y + (1 - (block.angle % 4))*block.squares[i].y;
        } else {
          point.x = block.x - (2 - (block.angle % 4))*block.squares[i].y;
          point.y = block.y + (2 - (block.angle % 4))*block.squares[i].x;
        }
        if (shadow) {
          point.y += block.rowsFree;
          drawBoardSquare(bd, point.y, point.x, block.color, true);
        } else {
          drawBoardSquare(bd, point.y, point.x, Color.mix(block.color,
              Color.WHITE, Color.LAMBDA*(1 - Color.LAMBDA)));
        }
      }
    }

    private function drawBoardSquare(
        bd:BitmapData, i:int, j:int, c:int, shadow:Boolean=false):void {
      i = i - (ROWS - VISIBLEROWS);
      if (i < 0 || i >= VISIBLEROWS || j < 0 || j >= COLS || c == 0x0) {
        return;
      }
      drawRect(bd, xPos + SQUAREWIDTH*j, yPos + SQUAREWIDTH*i,
               SQUAREWIDTH, SQUAREWIDTH, Color.lighten(c));
      fillRect(bd, xPos + SQUAREWIDTH*j + 1, yPos + SQUAREWIDTH*i + 1,
               SQUAREWIDTH - 2, SQUAREWIDTH - 2, c);
    }

    private function drawRect(
        bd:BitmapData, x:int, y:int, w:int, h:int, c:int):void {
      drawHLine(bd, x, y, w, c);
      drawHLine(bd, x, y + h - 1, w, c);
      drawVLine(bd, x, y, h, c);
      drawVLine(bd, x + w - 1, y, h, c);
    }

    private function fillRect(
        bd:BitmapData, x:int, y:int, w:int, h:int, c:int):void {
      bd.fillRect(new Rectangle(x, y, w, h), c);
    }

    private function drawTextField(bd:BitmapData, tf:TextField):void {
      bd.draw(tf, new Matrix(1, 0, 0, 1, tf.x, tf.y));
    }

    private function drawHLine(
        bd:BitmapData, x:int, y:int, w:int, c:int):void {
      bd.fillRect(new Rectangle(x, y, w, 1), c);
    }

    private function drawVLine(
        bd:BitmapData, x:int, y:int, h:int, c:int):void {
      bd.fillRect(new Rectangle(x, y, 1, h), c);
    }
  }
}
