package {
  import flash.display.MovieClip;
  import flash.events.TimerEvent;
  import flash.utils.Timer;
  import flash.utils.getTimer;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
  import flash.geom.*;
  import flash.text.TextField;

  public class Board extends MovieClip {
    private static const FRAMERATE:int = 60;
    private static const FRAMEDELAY:Number = 1000/FRAMERATE;

    // Timing
    private var _period:Number = FRAMEDELAY;
    private var _beforeTime:int = 0;
    private var _afterTime:int = 0;
    private var _timeDiff:int = 0;
    private var _sleepTime:int = 0;
    private var _overSleepTime:int = 0;
    private var _excess:int = 0;

    private var timer:Timer;
    private var curTime:int = 0;

    // Canvas
    private var canvasBD:BitmapData;
    private var canvasBitmap:Bitmap;

    public function Board() {
      canvasBD = new BitmapData(500, 375, false, 0xffffff);
      canvasBitmap = new Bitmap(canvasBD);
      addChild(canvasBitmap);

      timer = new Timer(FRAMEDELAY, 1);
      timer.addEventListener(TimerEvent.TIMER, gameLoop);
      timer.start();
    }

    private function gameLoop(e:TimerEvent):void {
      _beforeTime = getTimer();
      _overSleepTime = (_beforeTime - _afterTime) - _sleepTime;

      gameLoopUpdate();

      canvasBD.lock();
      canvasBD.fillRect(new Rectangle(0, 0, 500, 375), 0xffffff);
      gameLoopDraw();
      canvasBD.unlock();

      _afterTime = getTimer();
      _timeDiff = _afterTime - _beforeTime;
      _sleepTime = (_period - _timeDiff) - _overSleepTime;
      if(_sleepTime <= 0) {
        _excess -= _sleepTime;
        _sleepTime = 2;
      }

      timer.reset();
      timer.delay = _sleepTime;
      timer.start();

      while(_excess > _period) {
        gameLoopUpdate();
        _excess -= _period;
      }

      e.updateAfterEvent();
    }

    private function gameLoopUpdate():void {
      curTime++;
    }

    private function gameLoopDraw():void {
      canvasBD.setPixel(curTime, curTime, 0x000000);
      var tf:TextField = new TextField();
      tf.text = "some text";
      canvasBD.draw(tf);
    }
  }
}
