
from lib.utils import BitVector
import numpy as np

class ModulusExponential:
    def __call__(self, n:int, base:BitVector, power:BitVector ) -> BitVector:
        return BitVector.fromint(np.mod(np.power(base.__int_value, power.__int_value), n))