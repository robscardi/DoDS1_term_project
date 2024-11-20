from typing import Any
from lib.utils import BitVector
from lib.adders import *
from numpy import mod as npmod

class Modulus:
	def __call__(self, a:BitVector, n:BitVector) -> Any:
		return BitVector.fromint(npmod(a.__int_value,  n),  len(a))

class EuclidianModulus(Modulus):

	def __call__(self, a:BitVector, n:BitVector) -> BitVector:
		return __mod__(a, n)


# Function to compute the rest of Euclidian division (used on small numbers)
def __mod__(a : BitVector, n:BitVector) -> BitVector:
	r = a
	while r.get_value() >= n.get_value():
		r -= n
	return r