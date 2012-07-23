package {
  import flash.display.MovieClip;
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

  [SWF(width="367", height="546")]

  public class Board extends MovieClip {
    // Board size constants
    private static const NUMVISIBLEROWS:int = 24;
    private static const NUMROWS:int =
        (NUMVISIBLEROWS + Block.MAXBLOCKSIZE - 1);
    private static const NUMCOLS:int = 12;

    // Screen size constants
    private static const SQUAREWIDTH:int = 21;
    private static const BORDER:int = SQUAREWIDTH;
    private static const SIDEBOARD:int = 7*SQUAREWIDTH/2;
    private static const WIDTH:int = SQUAREWIDTH*NUMCOLS + SIDEBOARD + 2*BORDER;
    private static const HEIGHT:int = SQUAREWIDTH*NUMVISIBLEROWS + 2*BORDER;

    // Game engine constants
    private static const FRAMERATE:int = 60;
    private static const FRAMEDELAY:Number = 1000/FRAMERATE;

    // Canvas bitmap data
    private var xPos:int = SQUAREWIDTH;
    private var yPos:int = SQUAREWIDTH;
    private var canvasBD:BitmapData;
    private var canvasBitmap:Bitmap;

    // Timing variables
    private var timer:Timer;
    private var curTime:int = 0;
    private var beforeTime:int = 0;
    private var afterTime:int = 0;
    private var sleepTime:int = 0;
    private var numFrames:int = 0;
    private var lastSecond:int = 0;
    private var framerateText:TextField;

    // Board data structures
    private var data:Vector.<Vector.<int>>;

    public function Board() {
      canvasBD = new BitmapData(WIDTH, HEIGHT, false, 0xffffff);
      canvasBitmap = new Bitmap(canvasBD);
      addChild(canvasBitmap);

      framerateText = new TextField();
      framerateText.x = BORDER + SQUAREWIDTH*NUMCOLS + SQUAREWIDTH/2;
      framerateText.y = BORDER;
      framerateText.textColor = 0xffffff;

      Block.loadBlockData();

      data = new Vector.<Vector.<int>>();
      for (var i:int = 0; i < NUMROWS; i++) {
        data.push(new Vector.<int>());
        for (var j:int = 0; j < NUMCOLS; j++) {
          if (i > 12) {
            data[i].push(0xff);
          } else {
            data[i].push(0x0);
          }
        }
        data[i].fixed = true;
      }
      data.fixed = true;

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

    private function update():void {
      curTime++;
    }

    private function draw():void {
      canvasBD.lock();

      // Clear the screen and draw the border and grid lines.
      fillRect(canvasBD, 0, 0, WIDTH, HEIGHT, Color.BLACK);
      drawRect(canvasBD, BORDER/2 - 1, BORDER/2 - 1,
               WIDTH - BORDER + 2, HEIGHT - BORDER + 2, Color.GREEN);
      drawRect(canvasBD, BORDER/2, BORDER/2,
               WIDTH - BORDER, HEIGHT - BORDER, Color.GREEN);
      var lineColor:int = Color.lighten(Color.BLACK);
      for (var i:int = 0; i < NUMVISIBLEROWS; i++) {
        drawHLine(canvasBD, xPos, yPos + SQUAREWIDTH*i,
                  SQUAREWIDTH*NUMCOLS, lineColor);
        drawHLine(canvasBD, xPos, yPos + SQUAREWIDTH*(i + 1) - 1,
                  SQUAREWIDTH*NUMCOLS, lineColor);
      }
      for (i = 0; i < NUMCOLS; i++) {
        drawVLine(canvasBD, xPos + SQUAREWIDTH*i, yPos,
                  SQUAREWIDTH*NUMVISIBLEROWS, lineColor);
        drawVLine(canvasBD, xPos + SQUAREWIDTH*(i + 1) - 1, yPos,
                  SQUAREWIDTH*NUMVISIBLEROWS, lineColor);
      }

      // Draw the occupied squares on the board
      for (i = NUMROWS - NUMVISIBLEROWS; i < NUMROWS; i++) {
        for (var j:int = 0; j < NUMCOLS; j++) {
          drawBoardSquare(canvasBD, i, j, data[i][j]);
        }
      }

      drawTextField(canvasBD, framerateText);

      canvasBD.unlock();
    }

    private function drawBoardSquare(
        bd:BitmapData, i:int, j:int, c:int):void {
      i = i - (NUMROWS - NUMVISIBLEROWS);
      if (i < 0 || c == 0x0) {
        return;
      }
      drawRect(bd, xPos + SQUAREWIDTH*j, yPos + SQUAREWIDTH*i,
               SQUAREWIDTH, SQUAREWIDTH, Color.lighten(c));
      fillRect(bd, xPos + SQUAREWIDTH*j + 1, yPos + SQUAREWIDTH*i + 1,
               SQUAREWIDTH - 2, SQUAREWIDTH - 2, c);
    }

    private function drawHLine(
        bd:BitmapData, x:int, y:int, w:int, c:int):void {
      bd.fillRect(new Rectangle(x, y, w, 1), c);
    }

    private function drawVLine(
        bd:BitmapData, x:int, y:int, h:int, c:int):void {
      bd.fillRect(new Rectangle(x, y, 1, h), c);
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
  }
}
