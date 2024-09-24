from lib.modulus_exponential import ModulusExponential
from lib.utils import BitVector
from lib.modulus_multiplier import Montgomery
from lib.multiplier import *


def main():
     
    a = input("insert base")
    b = input("insert power")
    n = input("insert modulus")

    modexp = ModulusExponential()
    print(modexp(n, BitVector.fromint(a), BitVector.fromint(b) ))

