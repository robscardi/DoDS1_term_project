from typing import overload
from lib.utils import BitVector
from lib.multiplier import Multiplier
from lib.modulus import Modulus
import numpy as np


class ModulusMultiplier:
    def __call__(self, n:int, a:BitVector, b:BitVector) -> BitVector:
        return BitVector.fromint(np.mod(a.__int_value*b.__int_value, n))

class BlakleyMethod(ModulusMultiplier):
    def __init__(self, mod:Modulus) -> None:
        super().__init__()
        self.mod = mod

    def __call__(self, n:int, a:BitVector, b:BitVector ):
        assert(len(a) == len(b))
        res = BitVector.fromint(0, len(a))
        for i in range(0, len(a)):
            addendum = BitVector.fromstr("0"*len(a)) if a[len(a) -i -1] == 0 else b
            res = (res << 1) + addendum
            res = self.mod(res, n)
        n = BitVector.fromint(n, len(res))
        if res >= n:
            res -= n
        if res >=  n:
            res -= n
        
        return res