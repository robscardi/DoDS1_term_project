from typing import Any
from lib.utils import BitVector
from lib.adders import *
from numpy import mod as npmod

class Modulus:
	def __call__(self, a:BitVector, n:int) -> Any:
		return BitVector.fromint(npmod(a.__int_value,  n),  len(a))

class EuclidianModulus(Modulus):

	def __call__(self, a:BitVector, n:int) -> BitVector:
		return __mod__(a, BitVector.fromint(n, len(a)))


# Function to compute the rest of Euclidian division (used on small numbers)
def __mod__(a : BitVector, k:BitVector) -> BitVector:
	r = a
	while r > k:
		r -= k
	return r

# Function to return the value of (bin % k) for big numbers 
def getMod(value:BitVector, n:BitVector): 

	assert(n.get_value() > 0)
	mem = BitVector.fromint(0, len(value))
	pt = BitVector.fromint(1, len(value))
	for i in range(0, len(value)):
		pt = __mod__(pt, n)
		index = BitVector.fromint(1, len(value))
		pwrTwo = (index << i) & value
		if pwrTwo.get_value() : mem = mem +pt
		pt = pt <<1

	return __mod__(mem, n)