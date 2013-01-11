package {
  public class Color {
    public static const LAMBDA:Number = 0.20;

    public static const BLACK:int = 0x00000000;
    public static const GRAY:int = 0x00ffffff;
    public static const WHITE:int = 0x00ffffff;
    public static const RED:int = 0x00ff0000;
    public static const LIME:int = 0x0000ff00;
    public static const BLUE:int = 0x000000ff;
    public static const CYAN:int = 0x0000ffff;
    public static const PURPLE:int = 0x00800080;
    public static const YELLOW:int = 0x00ffff00;
    public static const ORANGE:int = 0x00ffa500;
    public static const DARKORANGE:int = 0x00ff8c00;
    public static const ORANGERED:int = 0x00ff4500;
    public static const TAN:int = 0x00d2b48c;
    public static const SALMON:int = 0x00fa8072;
    public static const DARKRED:int = 0x00b21111;
    public static const PURPLERED:int = 0x008b0011;
    public static const XLIGHTBLUE:int = 0x0087ceeb;
    public static const LIGHTBLUE:int = 0x004169e1;
    public static const PURPLEBLUE:int = 0x0000008b;
    public static const HOTPINK:int = 0x00ff00ff;
    public static const PLUM:int = 0x00dda0dd;
    public static const ORCHID:int = 0x00da70d6;
    public static const DARKPINK:int = 0x009966cc;
    public static const TURQUOISE:int = 0x0048d1cc;
    public static const DARKGREEN:int = 0x0020b2aa;
    public static const GREEN:int = 0x003cb371;
    public static const LIGHTGREEN:int = 0x0098fb98;
    public static const XXXLIGHTGRAY:int = 0x00dddddd;
    public static const XXLIGHTGRAY:int = 0x00cccccc;
    public static const XLIGHTGRAY:int = 0x00bbbbbb;
    public static const LIGHTGRAY:int = 0x00aaaaaa;
    public static const GOLD:int = 0x00ffd700;
    public static const STAIRCASE:int = 0x00b8860b;

    public static function mix(c1:int, c2:int, lambda:Number):int {
      var r:int = (1 - lambda)*(c1 >> 16 & 0xff) + lambda*(c2 >> 16 & 0xff);
      var g:int = (1 - lambda)*(c1 >> 8 & 0xff) + lambda*(c2 >> 8 & 0xff);
      var b:int = (1 - lambda)*(c1 & 0xff) + lambda*(c2 & 0xff);
      return (Math.min(r, 255) << 16) +
             (Math.min(g, 255) << 8) + Math.min(b, 255);
    }

    public static function lighten(c:int):int {
      return mix(c, WHITE, LAMBDA);
    }

    public static function tint(c:int):int {
      return mix(WHITE, c, LAMBDA);
    }

    public static function colorCode(index:int):int {
      return mix(rainbowCode(index), WHITE, 3.2*LAMBDA);
    }

    public static function washedOutCode(index:int):int {
      var c:int = rainbowCode(index);
      return (c >> 8 & 0xff << 16) + (c >> 16 & 0xff << 8) + 255;
    }

    // the difficulty coloring of blocks in multiplayer games
    public static function difficultyColor(c:int, level:int, maxLevel:int):int {
      var r:int = c >> 16 & 0xff;
      var g:int = c >> 8 & 0xff;
      var b:int = c & 0xff;

      if (level > 0) {
        var blueShift:int = (g/2 << 16) + (r/2 << 8) + 255;
        var lambda:Number = (0.8 + (1.0*level)/maxLevel)/2.0;
        return mix(mix(blueShift, RED, lambda), WHITE, LAMBDA);
      } else {
        return mix((g/4 << 16) + (r/2 << 8) + (255 + b)/2, WHITE, LAMBDA);
      }
    }

    public static function rainbowCode(index:int):int {
      switch (index) {
        case 0:
          return WHITE;
        case 1:
          return XXXLIGHTGRAY;
        case 2:
          return XXLIGHTGRAY;
        case 3:
          return YELLOW;
        case 4:
          return XLIGHTGRAY;
        case 5:
          return XLIGHTBLUE;
        case 6:
          return SALMON;
        case 7:
          return PLUM;
        case 8:
          return GOLD;
        case 9:
          return ORCHID;
        case 10:
          return LIGHTGREEN;
        case 11:
          return LIGHTGRAY;
        case 12:
          return LIGHTBLUE;
        case 13:
          return RED;
        case 14:
          return BLUE;
        case 15:
          return DARKRED;
        case 16:
          return PURPLERED;
        case 17:
          return PURPLEBLUE;
        case 18:
          return HOTPINK;
        case 19:
          return PURPLE;
        case 20:
          return TAN;
        case 21:
          return DARKORANGE;
        case 22:
          return DARKGREEN;
        case 23:
          return STAIRCASE;
        case 24:
          return ORANGERED;
        case 25:
          return TURQUOISE;
        case 26:
          return DARKPINK;
        case 27:
          return ORANGE;
        case 28:
          return GREEN;
        default:
          return RED;
      }
    }
  }
}
