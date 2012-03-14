package {
  import flash.display.MovieClip;
  import flash.events.TimerEvent;
  import flash.utils.Timer;
  import flash.utils.getTimer;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
  import flash.geom.*;
  import flash.text.TextField;

  [SWF(width="320", height="480")]

  public class Board extends MovieClip {
    // Game engine constants
    private static const WIDTH:int = 320;
    private static const HEIGHT:int = 480;
    private static const FRAMERATE:int = 60;
    private static const FRAMEDELAY:Number = 1000/FRAMERATE;

    // Timing variables
    private var timer:Timer;
    private var curTime:int = 0;

    private var beforeTime:int = 0;
    private var afterTime:int = 0;
    private var sleepTime:int = 0;

    private var numFrames:int = 0;
    private var lastSecond:int = 0;
    private var framerateText:TextField = new TextField();

    // Canvas bitmap data
    private var canvasBD:BitmapData;
    private var canvasBitmap:Bitmap;

    public function Board() {
      canvasBD = new BitmapData(WIDTH, HEIGHT, false, 0xffffff);
      canvasBitmap = new Bitmap(canvasBD);
      addChild(canvasBitmap);

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

      canvasBD.fillRect(new Rectangle(0, 0, WIDTH, HEIGHT), 0xffffff);
      canvasBD.setPixel(curTime, curTime, 0x000000);
      canvasBD.draw(framerateText);

      canvasBD.unlock();
    }
  }
}
