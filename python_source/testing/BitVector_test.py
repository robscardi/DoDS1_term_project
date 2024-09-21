from lib.utils import BitVector
import unittest

class TestBitVector(unittest.TestCase):
    def test_and(self):
        a = BitVector.fromint(45)
        b = BitVector.fromint(56)
        c = a & b
        cc = BitVector.fromstr("101000")
        self.assertEqual(c, cc )

    def test_not(self):
        a = BitVector.fromint(56)
        b = ~BitVector.fromstr("000111")

        self.assertEqual(a, b)