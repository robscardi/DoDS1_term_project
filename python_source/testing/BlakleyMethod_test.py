from unittest import TestCase
from lib.modulus_multiplier import BlakleyMethod
from lib.modulus import *
from lib.utils import BitVector

class BlakleyMethodTest(TestCase):

    def test_BM(self):
        BM = BlakleyMethod(EuclidianModulus())
        a = BitVector.fromint(7, 16)
        b = BitVector.fromint(3, 16)
        n = BitVector.fromint(20,16)
        res = BM(n, a, b)
        self.assertEqual(BitVector.fromint(1), res)
    
    def test_BM2(self):
        BM = BlakleyMethod(EuclidianModulus())
        a = BitVector.fromint(3649, 256)
        b = BitVector.fromint(2753, 256)
        n = BitVector.fromint(28097,256)
        res = BM(n, a, b)
        self.assertEqual(BitVector.fromint((3649*2753)%28097), res)