import numpy as np

a = int("0x76e38fd657e8b6db8f7d173f2cc198a5cd02657c45d264c8629015c4b22ec17e", 0)
b = int("0x76e38fd657e8b6db8f7d173f2cc198a5cd02657c45d264c8629015c4b22ec17e", 0)
m = int("0xb0f76b9c82af81aaf51f3dc145c3faf5c40841144b4772616411aa362640f1ce", 0)

res = ((a*b)% m)
print(hex(res))

r = 0
a_str = format(a, '0256b')
print(a_str)
f = open("output_test_mult.txt", "+w")
for i in a_str:
    r = r*2 + (b if i == '1' else 0)
    print(hex(r))
    f.write(hex(r) +"\n")
    r = (r % m)
    
    print(hex(r))
    f.write(hex(r)+"\n")
print(hex((r % m)))
f.write(hex(r%m)+"\n")