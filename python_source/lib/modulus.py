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
class BlakleyModulus(Modulus):
	def __call__(self, a:BitVector, n:BitVector) -> BitVector:
		i_a = a.get_value()
		i_n = n.get_value()
		if(i_a < i_n) :
			return BitVector.fromint(i_a, len(a))
		elif(i_a-i_n < i_n):
			return BitVector.fromint(i_a-i_n, len(a))
		else :
			return BitVector.fromint(i_a-2*i_n, len(a))

# Function to compute the rest of Euclidian division (used on small numbers)
def __mod__(a : BitVector, n:BitVector) -> BitVector:
	r = a
	while r.get_value() >= n.get_value():
		r -= n
	return r