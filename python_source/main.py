from lib.modulus_exponential import *
from lib.utils import BitVector
from lib.modulus_multiplier import *
from lib.multiplier import *
from lib.modulus import *


def main():
     
    n = int(input("insert modulus\n"))
    assert n < 2**256, "n should be representable in 256 bits"
    a = int(input("insert base\n"))
    assert a < n, "a needs to be strictly less than n (Blakley implementation)"
    b = int(input("insert power\n"))
    assert b < n, "b needs to be strictly less than n (Blakley implementation)"
    
    modexp:ModulusExponential = OctalMethod(BlakleyMethod(EuclidianModulus()))
    #a, b and n should be representable with 256 bit. for bigger values modify the bit vector lenght inside the
    #BitVector.fromint function
    bitlen = 256

    '''Very large numbers example
    b = int("b3fc92111676e77368df192fb4d1de2130288dcf05f30f786cd9aa71e313f0fc",16)
    n = int("cc19aafd739949c1c0f0ad9349c7e55f62a7933bc410b2ab1a1ec897bb315b85",16)
    a = int("0012d526d29b710cf425f010af234dfcc237d091ef733864575fd8a05faf9511",16)
    '''
    result = modexp(BitVector.fromint(n,bitlen), BitVector.fromint(a, bitlen), BitVector.fromint(b, bitlen) ).get_value()
    bin_result = modexp(BitVector.fromint(n,bitlen), BitVector.fromint(a, bitlen), BitVector.fromint(b, bitlen) ).get_str()
    correct_result = pow(a,b,n)

    print("Result = ", result)
    print("Binary writing : ", bin_result)
    assert result == correct_result, f"TEST FAILED | Correct result = {correct_result} | Result = {result}"
    print("TEST SUCCESFUL")

    
if __name__ == "__main__":
    main()