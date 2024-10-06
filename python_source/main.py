from lib.modulus_exponential import *
from lib.utils import BitVector
from lib.modulus_multiplier import *
from lib.multiplier import *
from lib.modulus import *


def main():
     
    n = int(input("insert modulus\n"))
    a = int(input("insert base\n"))
    assert a < n, "a needs to be strictly less than n (Blakley implementation)"
    b = int(input("insert power\n"))
    assert b < n, "b needs to be strictly less than n (Blakley implementation)"
    
    modexp:ModulusExponential = BinaryMethod(BlakleyMethod(EuclidianModulus()))
    #a, b and n should be representable with 256 bit. for bigger values modify the bit vector lenght inside the
    #BitVector.fromint function
    bitlen = 256
    print(modexp(n, BitVector.fromint(a, bitlen), BitVector.fromint(b, bitlen) ).get_value())
    print(modexp(n, BitVector.fromint(a, bitlen), BitVector.fromint(b, bitlen) ).get_str())

if __name__ == "__main__":
    main()