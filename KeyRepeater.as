package {
  import flash.events.KeyboardEvent;
  import flash.utils.getTimer;

  import Key;
  import RepeatHandler;

  public class KeyRepeater {
    private var pause:int;
    private var repeat:int;
    private var handler:RepeatHandler;
    private var isKeyDown:Vector.<Boolean>;
    private var nextFireTime:Vector.<int>;
   
    public function KeyRepeater(p:int, r:int, h:RepeatHandler) {
      pause = p;
      repeat = r;
      handler = h;
      
      isKeyDown = new Vector.<Boolean>();
      nextFireTime = new Vector.<int>();
      for (var i:int = 0; i < Key.NUMKEYS; i++) {
        isKeyDown.push(false);
        nextFireTime.push(-1);
      }
      isKeyDown.fixed = true;
      nextFireTime.fixed = true;
    }

    public function keyPressed(keyEvent:KeyboardEvent):void {
      var key:int = Key.translateKeyCode(keyEvent.keyCode);
      if (key >= 0) {
        isKeyDown[key] = true;
      }
    }

    public function keyReleased(keyEvent:KeyboardEvent):void {
      var key:int = Key.translateKeyCode(keyEvent.keyCode);
      if (key >= 0) {
        isKeyDown[key] = false;
      }
    }

    public function query():void {
      var curTime:int = getTimer();
      for (var i:int = 0; i < Key.NUMKEYS; i++) {
        if (isKeyDown[i]) {
          if (nextFireTime[i] < 0) {
            handler.repeaterPress(i);
            nextFireTime[i] = curTime + pause;
          } else if (curTime > nextFireTime[i]) {
            handler.repeaterPress(i);
            nextFireTime[i] = curTime + repeat;
          }
        } else if (nextFireTime[i] > 0) {
          handler.repeaterRelease(i);
          nextFireTime[i] = -1;
        }
      }
    }
  }
}
