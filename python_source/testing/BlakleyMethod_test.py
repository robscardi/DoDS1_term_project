from unittest import TestCase
from lib.modulus_multiplier import BlakleyMethod
from lib.modulus_multiplier import BlakleyMethodParallel
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
    def test_BMP(self):
        BM =BlakleyMethod(EuclidianModulus())
        a = BitVector.fromint(45, 16)
        b = BitVector.fromint(64, 16)
        n = 300
        res = BM(n, a, b)
        BMP = BlakleyMethodParallel(EuclidianModulus())
        res2 = BMP(n, a, b)

        self.assertEqual(res2, res)