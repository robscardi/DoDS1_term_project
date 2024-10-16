import numpy as np

a = 3649
b = 2753
m = 28097

res = np.mod(a*b, m)
print(res)
r = 0
a_str = format(a, '032b')
print(a_str)
for i in a_str:
    r = r*2 + (b if i == '1' else 0)
    print(r)
    r = np.mod(r, m)
    print(r)
print(np.mod(r, m))
