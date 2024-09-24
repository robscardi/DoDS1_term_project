from lib.modulus_exponential import *
from lib.utils import BitVector
from lib.modulus_multiplier import *
from lib.multiplier import *


def main():
     
    a = input("insert base")
    b = input("insert power")
    n = input("insert modulus")

    modexp:ModulusExponential = BinaryMethod(ModulusMultiplier())
    print(modexp(n, BitVector.fromint(a), BitVector.fromint(b) ))

