from unittest import TestCase
from lib.modulus_multiplier import BlakleyMethod
from lib.modulus_exponential import OctalMethod
from lib.modulus import *
from lib.utils import BitVector

class OctalMethodTest(TestCase):

    def test_OctM(self):
        OM =OctalMethod(BlakleyMethod(EuclidianModulus()))
        a = BitVector.fromint(50, 256)
        b = BitVector.fromint(17, 256)
        n = BitVector.fromint(143,256)
        res = OM(n, a, b)
        self.assertEqual(BitVector.fromint(85), res)
