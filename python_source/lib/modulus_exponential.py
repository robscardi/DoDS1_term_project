
from .utils import BitVector
from .modulus_multiplier import ModulusMultiplier
import numpy as np

class ModulusExponential:
    def __init__(self) -> None:
        pass
    def __call__(self, n:int, base:BitVector, power:BitVector ) -> BitVector:
        return BitVector.fromint(np.mod(np.power(base.__int_value, power.__int_value), n))

class BinaryMethod(ModulusExponential):
    def __init__(self, modMult:ModulusMultiplier) -> None:
        super().__init__()
        self.modMult = modMult

    def __call__(self, n:int,M:BitVector, e:BitVector) -> BitVector:

        
        print(e.__len__())
        if e.__getitem__(e.__len__() - 1) == 1:
            z = M.__value__()
            C = BitVector.fromint(z, len(M))
        else:
            C = BitVector.fromint(1, len(M))
        print(C.__strvalue__())
        for i in reversed(range(e.__len__()-1)):
            C = self.modMult(n, C,C)
            if e.__getitem__(i) == 1:
                C =  self.modMult(n,C,M)
        print("cripyted C: \n")
        print(C.__strvalue__())
        print(C.__value__())
        return C
         