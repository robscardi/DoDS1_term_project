from typing import Self

class BitVector:
    
    def __init__(self,int_value:int, bit_string:str) -> None:
        self.__int_value:int = int_value
        self.__bit_string:str = bit_string
        self.__len = len(bit_string)
    
    @classmethod
    # Construct a BitVector given the integer value and the bit length. If len is None then the smallest bit length is chosen
    def fromint(cls, value: int, len:int = None):
        
        if len is None:
            return cls(int_value=value, bit_string=format(value, 'b' )) 
        else:    
            return cls(int_value=value, bit_string=format(value, '0' + str(len) + 'b' )) 
    
    @classmethod
    # Construct a BitVector starting from a binary string 
    def fromstr(cls, value: str):
        return cls(int_value=int(value, 2), bit_string=value) 
    
       
    def __or__(self, value: Self) -> Self: 
        return BitVector.fromint(self.__int_value | value.__int_value)
        
    def __and__(self, value:Self) -> Self:
        return BitVector.fromint(self.__int_value & value.__int_value)
    
    def __xor__(self, value: Self) -> Self:
        return BitVector.fromint(self.__int_value ^ value.__int_value)
    def __invert__(self:Self) ->Self:
        return BitVector.fromstr(''.join('1' if char == '0' else '0' for char in self.__bit_string))

    def __add__(self, value: Self) -> Self:
        return BitVector.fromint(self.__int_value + value.__int_value, max(len(self), len(value)))        
    def __sub__(self, value:Self) -> Self:
        return BitVector.fromint(self.__int_value - value.__int_value, max(len(self), len(value)))
    
    def __eq__(self, value:Self) -> bool:
        return self.__int_value == value.__int_value

    def __gt__(self, value:Self) -> bool:   
        return self.__int_value > value.__int_value
    def __lt__(self, value:Self) -> bool:   
        return self.__int_value < value.__int_value
    def __ge__(self, value:Self) -> bool:
        return self > value | self == value

    def __le__(self, value:Self) -> bool:
        return self < value | self == value

    def __getitem__(self, key:int):
        return bool(int(self.__bit_string[self.__len - key-1]))

    def __setitem__(self, key:int, value:bool):
        self.__bit_string[self.__len -key -1] = str(value)
        self.__int_value(int(self.__bit_string, 2))

    def __len__(self):
        return self.__len
    def get_value(self):
        return self.__int_value
    def get_str(self):
        return self.__bit_string
    
    def __lshift__(self, n:int):
        return BitVector.fromint(self.__int_value << n, self.__len)
    
    def __rshift__(self, n:int):
        return BitVector.fromint(self.__int_value >> n, self.__len)

