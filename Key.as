package {
  public class Key {
    public static const NUMKEYS:int = 4;

    public static const MOVEUP:int = 0;
    public static const MOVERIGHT:int = 1;
    public static const MOVEDOWN:int = 2;
    public static const MOVELEFT:int = 3;

    public static function translateKeyCode(keyCode:int):int {
      switch (keyCode) {
        case 38: return Key.MOVEUP;
        case 39: return Key.MOVERIGHT;
        case 40: return Key.MOVEDOWN;
        case 37: return Key.MOVELEFT;
        default: return -1;
      }
    }
  }
}
