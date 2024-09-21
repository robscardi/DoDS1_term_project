from typing import Self

class BitVector:
    
    def __init__(self, len:int, int_value:int, bit_string:str) -> None:
        self.__len = len
        self.__int_value = int_value
        self.__bit_string = bit_string

    @classmethod
    def fromint(cls, value: int):
        return cls(len=len(format(value, 'b' )), int_value=value, bit_string=format(value, 'b' )) 
    
    @classmethod
    def fromstr(cls, value: str):
        return cls(len=len(value), int_value=int(value, 2), bit_string=value) 
    
       
    def __or__(self, value: Self) -> Self: 
        return BitVector.fromint(self.__int_value | value.__int_value)
        
    def __and__(self, value:Self) -> Self:
        return BitVector.fromint(self.__int_value & value.__int_value)
    
    def __xor__(self, value: Self) -> Self:
        return BitVector.fromint(self.__int_value ^ value.__int_value)
    def __invert__(self:Self) ->Self:
        return BitVector.fromstr(''.join('1' if char == '0' else '0' for char in self.__bit_string))

    def __add__(self, value: Self) -> Self:
        return BitVector.fromint(self.__int_value + value.__int_value)        
    def __sub__(self, value:Self) -> Self:
        return BitVector.fromint(self.__int_value - value.__int_value)
    def __eq__(self, value:Self) -> bool:
        return self.__int_value == value.__int_value

    def __getitem__(self, key:int):
        return bool(int(self.__bit_string[self.__len - key-1]))

    def __setitem__(self, key:int, value:bool):
        self.__bit_string[self.__len -key -1] = str(value)
        self.__int_value(int(self.__bit_string, 2))

    def __len__(self):
        return self.__len

