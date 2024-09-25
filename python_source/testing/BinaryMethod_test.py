from unittest import TestCase
from lib.modulus_multiplier import BlakleyMethod
from lib.modulus_exponential import BinaryMethod
from lib.modulus import *
from lib.utils import BitVector

class BinaryMethodTest(TestCase):

    def test_BinM(self):
        BM = BinaryMethod(BlakleyMethod(EuclidianModulus()))
        a = BitVector.fromint(50, 32)
        b = BitVector.fromint(17, 32)
        n = 143
        res = BM(n, a, b)
        self.assertEqual(BitVector.fromint(85), res)