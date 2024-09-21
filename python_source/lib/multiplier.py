from lib.utils import BitVector
from lib.adders import *
import numpy as np
from functools import reduce


class Multiplier:
    def __call__(self, a:BitVector, b:BitVector) -> BitVector:
        return BitVector.fromint(a.__int_value*b.__int_value)

#functor, see https://docs.python.org/3/reference/datamodel.html#object.__call__ 

class DaddaMultiplier(Multiplier):

    def __init__(self, input_dim:int) -> None:
        super().__init__()
        self.input_dim = input_dim
        self.d = 2
        self.j = 1
        while (self.d < input_dim):
            self.d = int(np.floor(1.5*self.d))
            self.j += 1
        self.matrix = list()

    def __call__(self, a:BitVector, b: BitVector) -> BitVector:

        assert(len(a) == len(b))
        assert(len(a) == self.input_dim)
        # Algorithm by L. G. de Castro, H. S. Ogawa and B. d. C. Albertini, "Automated Generation of HDL Implementations of Dadda and Wallace Tree Multipliers," 2017 VII Brazilian Symposium on Computing Systems Engineering (SBESC), Curitiba, PR, Brazil, 2017, pp. 17-22, doi: 10.1109/SBESC.2017.9.
        
        #generate partial multiplication matrix
        for c in range(0, self.input_dim):
            col_c = list()
            for k in range(0, c+1):
                col_c.insert(c, a[c-k] & b[k])
            self.matrix.append(col_c)
        for c in range(self.input_dim, 2*self.input_dim-1):
            i = 0
            col_i = list()
            for k in range(c-self.input_dim+1, self.input_dim):
                col_i.insert(i,  a[c-k] & b[k])
                i += 1
            self.matrix.insert(c, col_i)
        
        self.matrix.append(list())
        #Dadda reduction 
        max_length = lambda lst: max(map(len, lst))

        FA = FullAdder()
        HA = HalfAdder()
        def FA_grouping(lst:list[list], i):
            pa = FA(lst[i].pop(),lst[i].pop(),lst[i].pop())
            lst[i].append(pa[0])
            if (pa[1]): lst[i+1].append(pa[1])

        def HA_grouping(lst:list[list], i):
            pa = HA(lst[i].pop(),lst[i].pop())
            lst[i].append(pa[0])
            
            if (pa[1]): lst[i+1].append(pa[1])
                
        M = len(self.matrix)
        while max_length(self.matrix) > 2:
            for c in range(2,M):
                len_c = len(self.matrix[c])
                if len_c > self.d +1:
                    FA_grouping(self.matrix, c)
                elif len_c > self.d:
                    HA_grouping(self.matrix, c)
            self.d = int(np.ceil(self.d/1.5))

        #final reduction
        bitstring = ''.join('1' if any(sublist) else '0' for sublist in self.matrix)
        return BitVector.fromstr(bitstring[::-1])   