from lib.utils import BitVector
from lib.adders import *

# Function to compute the rest of Euclidian division (used on small numbers)
def mod(a : BitVector,k):
	r = a
	while r > k:
		r -= k
	return r

# Function to return the value of (bin % k) 
def getMod(bin, k): 
    n = len(bin)
	
	# pwrTwo[i] will store ((2^i) % k) 
    pwrTwo = [0] * n
	pwrTwo[0] = mod(1,k) 
	r = mod(2,k)
	for i in range(1, n): 
		pwrTwo[i] = pwrTwo[i - 1] * r 
		pwrTwo[i] = mod(pwrTwo,k) 

	# To store the result 
	res = 0
	j = n - 1
	for i in range(0,n): 

		# If current bit is 1 
		if (bin[j] == '1') : 

			# Add the current power of 2 
			res += (pwrTwo[i]) 
			res = mod(res,k) 
			
		i += 1
		j -= 1

	return res 

# Driver code 
bin = "1101"
n = len(bin) 
k = 45

print(getMod(bin, n, k)) 

# This code is contributed by
# divyamohan123
