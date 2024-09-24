from unittest import TestCase
from lib.modulus_multiplier import BlakleyMethod
from lib.modulus import *
from lib.utils import BitVector

class BlakleyMethodTest(TestCase):

    def test_BM(self):
        BM = BlakleyMethod(EuclidianModulus())
        a = BitVector.fromint(7, 16)
        b = BitVector.fromint(3, 16)
        n = 20
        res = BM(n, a, b)
        self.assertEqual(BitVector.fromint(1), res)