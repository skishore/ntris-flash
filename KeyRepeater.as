package {
  import flash.events.KeyboardEvent;

  import Key;

  public class KeyRepeater {
    private var pause:int;
    private var repeat:int;
    private var isKeyDown:Vector.<Boolean>;
    private var fireFrames:Vector.<int>;
   
    public function KeyRepeater(p:int, r:int) {
      pause = p;
      repeat = r;
      
      isKeyDown = new Vector.<Boolean>();
      fireFrames = new Vector.<int>();
      for (var i:int = 0; i < Key.NUMKEYS; i++) {
        isKeyDown.push(false);
        fireFrames.push(-1);
      }
      isKeyDown.fixed = true;
      fireFrames.fixed = true;
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
        if (fireFrames[key] < 0) {
          fireFrames[key] == 0;
        } else {
          fireFrames[key] = -1;
        }
      }
    }

    public function query(keysFired:Vector.<int>):void {
      keysFired.length = 0;

      for (var key:int = 0; key < Key.NUMKEYS; key++) {
        if (isKeyDown[key]) {
          if (fireFrames[key] < 0) {
            keysFired.push(key);
            fireFrames[key] = pause;
          } else if (fireFrames[key] == 0) {
            if (Key.doesKeyRepeat[key]) {
              keysFired.push(key);
            }
            fireFrames[key] = (key == Key.DOWN ? 0 : repeat);
          } else {
            fireFrames[key]--;
          }
        } else if (fireFrames[key] == 0) {
          keysFired.push(key);
          fireFrames[key] = -1;
        }
      }
    }
  }
}
