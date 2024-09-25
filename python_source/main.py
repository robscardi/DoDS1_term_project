from lib.modulus_exponential import *
from lib.utils import BitVector
from lib.modulus_multiplier import *
from lib.multiplier import *
from lib.modulus import *


def main():
     
    a = int(input("insert base\n"))
    b = int(input("insert power\n"))
    n = int(input("insert modulus\n"))

    modexp:ModulusExponential = BinaryMethod(BlakleyMethod(EuclidianModulus()))
    print(modexp(n, BitVector.fromint(a, 32), BitVector.fromint(b, 32) ))

if __name__ == "__main__":
    main()