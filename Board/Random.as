package {
  import flash.utils.getTimer;

  public class Random {
    private var MT:Vector.<uint> = new Vector.<uint>(624, true);
    private var index:int;

    public function Random(s:int=0) {
      s = s || getTimer();
      seed(s);
    }

    public function seed(s:int):void {
      index = 0;
      for (var i:int = 0; i < 624; i++) {
        MT[i] = s;
        s = 1812433253 * (Number(s ^ (s >>> 30)) + i & 0xFFFFFFFF);
      }
    }

    public function randword():uint {
      var i:int = index;
      index = (index + 1) % 624;
      var y:uint = MT[i];
      var z:uint = (MT[i] & 0x80000000) | (MT[index] & 0x7fffffff);
      MT[i] = (MT[(i + 397) % 624] ^ (z >>> 1)) ^ (0x9908b0df & (-(z & 1)));
      y ^= y >>> 11;
      y ^= (y << 7) & 0x9d2c5680;
      y ^= (y << 15) & 0xefc60000;
      y ^= y >>> 18;
      return y;
    }

    public function random():Number {
      return randword() / (uint.MAX_VALUE + Number.MIN_VALUE);
    }

    public function randint(n:int):int {
      return randword() % n;
    }
  }
}
