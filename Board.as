package {
  import flash.display.MovieClip;
  import flash.events.TimerEvent;
  import flash.utils.Timer;

  public class Board extends MovieClip {
    private static const FRAMERATE:int = 60;
    private static const FRAMEDELAY:Number = 1000/FRAMERATE;

    private var timer:Timer;
    private var curTime:int = 0;

    public function Board() {
      //this.y = -62;

      timer = new Timer(FRAMEDELAY, 1);
      timer.addEventListener(TimerEvent.TIMER, gameLoop);
      timer.start();
    }

    private function gameLoop(e:TimerEvent):void {
      this.graphics.lineStyle(1, 0x000000);
      this.graphics.moveTo(1, 1);
      this.graphics.lineTo(5, 1);
      this.graphics.lineTo(5, 5);
      this.graphics.lineTo(1, 5);
	  this.graphics.lineTo(1, 1);
	  this.graphics.lineTo(492, 1);
	  this.graphics.lineTo(492, 5);
	  this.graphics.lineTo(492, 375);
    }
  }
}
