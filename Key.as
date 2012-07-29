package {
  public class Key {
    public static const NUMKEYS:int = 7;

    public static const UP:int = 0;
    public static const RIGHT:int = 1;
    public static const DOWN:int = 2;
    public static const LEFT:int = 3;
    public static const DROP:int = 4;
    public static const HOLD:int = 5;
    public static const PAUSE:int = 6;

    public static const doesKeyRepeat:Vector.<Boolean> =
        Vector.<Boolean>([false, true, true, true, false, false, false]);

    public static function translateKeyCode(keyCode:int):int {
      switch (keyCode) {
        case 38: return UP;
        case 39: return RIGHT;
        case 40: return DOWN;
        case 37: return LEFT;
        case 32: return DROP;
        case 16: return HOLD;
        case 13: return PAUSE;
        case 80: return PAUSE;
        default: return -1;
      }
    }
  }
}
