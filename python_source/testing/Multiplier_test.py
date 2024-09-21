from lib.utils import BitVector
from lib.multiplier import DaddaMultiplier
import unittest

class DaddaMultiplierTest(unittest.TestCase):
    
    def test_multiply_16(self):
        mul = DaddaMultiplier(16)
        a = BitVector.fromstr("0000000101011100") #348
        b = BitVector.fromstr("0000000000110100") #52
        res = BitVector.fromstr("00000000000000000100011010110000") #348 * 52 = 18096
        c = mul(a, b)
        self.assertEqual(c, res)
