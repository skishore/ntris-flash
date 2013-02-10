package {
  import flash.utils.getTimer;

  // This is an ActionScript implementation of the Central Randomizer,
  // copyright 1997 by Paul Houle (paul@honeylocust.com).
  // See: http://www.honeylocust.com/javascript/randomizer.html
  public class Random {
    private static const MAX_SEED:int = 233280;
    private static var s:int = int(getTimer()) % MAX_SEED;

    public static function seed(new_s:int):void {
      s = new_s  % MAX_SEED;
    }

    public static function random():Number {
      s = (9301*s + 49297) % MAX_SEED;
      return 1.0*s/MAX_SEED;
    }

    public static function randint(n:int):int {
      s = (9301*s + 49297) % MAX_SEED;
      return Math.min(Math.floor(n*(1.0*s/MAX_SEED)), n - 1);
    }
  }
}
