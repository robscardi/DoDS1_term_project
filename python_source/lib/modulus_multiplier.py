from typing import overload
from lib.utils import BitVector
from lib.multiplier import Multiplier
from lib.modulus import Modulus
import numpy as np

#a.__value__()
class ModulusMultiplier:
    def __call__(self, n:BitVector, a:BitVector, b:BitVector) -> BitVector:
        return BitVector.fromint(np.mod(a.__value__()*b.__value__(), n.__value__()))


class BlakleyMethod(ModulusMultiplier):
    def __init__(self, mod:Modulus) -> None:
        super().__init__()
        self.mod = mod
    
    def __call__(self, n:BitVector, a:BitVector, b:BitVector ):
        assert len(a) == len(b), "The two inputs should have the same bit length" 
        res = BitVector.fromint(0, len(a))
        for i in range(0, len(a)):
            if a[len(a) -i -1] == 1:
                partial_sum = BitVector.fromstr("0"+res.get_str()+"0") + BitVector.fromstr("00"+b.get_str())
            else:
                partial_sum = BitVector.fromstr("0"+res.get_str()+"0")
            res = self.mod(partial_sum, BitVector.fromstr("00"+n.get_str()))
            res = BitVector.fromstr(res.get_str()[2:res.__len__()])

        return res

class BlakleyMethodParallel(ModulusMultiplier):
    def __init__(self, mod:Modulus) -> None:
        super().__init__()
        self.mod = mod

    def __call__(self, n: BitVector, a: BitVector, b: BitVector) -> BitVector:
        assert len(a) == len(b)
        partial_res = BitVector.fromint(0, len(a))
        for i in range(0, len(a)):
            partial_res += self.mod(b<<i, n) if a[i] else BitVector.fromint(0, len(a))
        return self.mod(partial_res, n)
