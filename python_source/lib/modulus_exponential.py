
from .utils import BitVector
from .modulus_multiplier import ModulusMultiplier
import numpy as np

class ModulusExponential:
    def __init__(self) -> None:
        pass
    def __call__(self, n:BitVector, base:BitVector, power:BitVector ) -> BitVector:
        return BitVector.fromint(np.mod(np.power(base.__int_value, power.__int_value), n.__int_value))

         
class OctalMethod(ModulusExponential):
    def __init__(self, modMult:ModulusMultiplier) -> None:
        super().__init__()
        self.modMult = modMult

    def __call__(self, n:BitVector,M:BitVector, e:BitVector) -> BitVector:

        #Precalculation of M**k[n] for k = 1 to 7
        pwr_M = [M]
        for k in range(6):
            M_wk = self.modMult(n,M,pwr_M[k])
            pwr_M.append(M_wk)

        #Initialization
        if e.__getitem__(255) == 1:
            C = M
        else:
            C = BitVector.fromint(1, len(M))
        i = 84

        while i >= 0:
            #C = C**8[n]
            C = self.modMult(n,C,C)
            C = self.modMult(n,C,C)
            C = self.modMult(n,C,C)
            f_i = (e.__getitem__(3*i+2))*4 + (e.__getitem__(3*i+1))*2 + (e.__getitem__(3*i))
            #One more modular multiplication if the 3-bits key block is not 0
            if f_i > 0:
                M_fi = pwr_M[f_i-1]
                C = self.modMult(n,C,M_fi)
            i -=1
        return C