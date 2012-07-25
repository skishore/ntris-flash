package {
  import flash.events.KeyboardEvent;
  import flash.utils.getTimer;

  import Key;

  public class KeyRepeater {
    private var pause:int;
    private var repeat:int;
    private var isKeyDown:Vector.<Boolean>;
    private var nextFireTime:Vector.<int>;
   
    public function KeyRepeater(p:int, r:int) {
      pause = p;
      repeat = r;
      
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

    public function query(keysFired:Vector.<int>):void {
      keysFired.length = 0;

      var curTime:int = getTimer();
      for (var i:int = 0; i < Key.NUMKEYS; i++) {
        if (isKeyDown[i]) {
          if (nextFireTime[i] < 0) {
            keysFired.push(i);
            nextFireTime[i] = curTime + pause;
          } else if (curTime > nextFireTime[i]) {
            keysFired.push(i);
            nextFireTime[i] = curTime + repeat;
          }
        } else if (nextFireTime[i] > 0) {
          nextFireTime[i] = -1;
        }
      }
    }
  }
}
