from typing import Any
from lib.utils import BitVector
from lib.multiplier import Multiplier
import numpy as np


class ModulusMultiplier:
    def __call__(self, n:int, a:BitVector, b:BitVector) -> Any:
        return BitVector.fromint(np.mod(a.__int_value*b.__int_value, n))

class BlakleyMethod(ModulusMultiplier):
    pass 
        
    
 