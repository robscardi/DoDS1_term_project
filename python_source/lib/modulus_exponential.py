
from lib.utils import BitVector
from lib.modulus_multiplier import ModulusMultiplier
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

    def __call__(self, M:BitVector, e:BitVector, n:int) -> BitVector:
        
        pass
         