import random
import io 
import os
import argparse


parser = argparse.ArgumentParser(description="create tests file for the 2024 AY Design of Digital System 1 teaching @NTNU RSA accelerator project")
parser.add_argument("test_name", help="name of the test file", type=str, action="store", default="")
parser.add_argument("test_length", help="total number of messages", type=int, action="store", default=0)
parser.add_argument('-g', '--generate',
                    help="generate random",
                    action='store_true')
args = parser.parse_args()

if (args.test_name != "") : test_name = args.test_name
if (args.test_length > 0) : test_length = args.test_length

while test_name == ""    : test_name = input("Test name: ")
while test_length <= 0   : test_length = int(input("Number of messages: "))

def generate_256_bit_number():
    """Generate a random 256-bit integer."""
    return random.getrandbits(256)

def modular_exponentiation(a, b, modulus):
    """Calculate (message ** key) % modulus efficiently."""
    return ((a*b) % modulus)

def write_to_file(filename, modulus, a_b_res):
    """Write key, modulus, messages, and their results to a file."""
    with open(filename, 'w') as f:
        # Write the key and modulus first
        f.write(f"{modulus:0{64}x}\n")
        for a,b, res in a_b_res :
            f.write(f"{a:0{64}x}\n")
            f.write(f"{b:0{64}x}\n")
            f.write(f"{res:0{64}x}\n\n")

def main():
    # Generate key and modulus
    modulus = generate_256_bit_number()
    # Specify the number of messages
    num_messages = test_length # Set your desired number here
    # Generate messages and compute their results
    a_b_res = []
    for _ in range(num_messages):
        a = generate_256_bit_number()
        b = generate_256_bit_number()
        while a > modulus :
            a = generate_256_bit_number()
        while b > modulus :
            b = generate_256_bit_number()
        
        result = modular_exponentiation(a, b, modulus)
        a_b_res.append((a, b, result))

    # Write everything to file
    write_to_file(f"{test_name}.txt", modulus, a_b_res)
    print(f"Data written to {test_name}.txt")

if __name__ == "__main__":
    main()
