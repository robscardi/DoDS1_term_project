from typing import Any
from .utils import BitVector


#returns a tuple in the form (S, C)
class HalfAdder :
    def __call__(self, a:bool , b:bool ) -> tuple[bool, bool]:
        return (a ^ b, a & b)

#returns a tuple in the form (S, C)
class FullAdder :
    def __call__(self, a:bool, b:bool, c:bool) -> tuple[bool, bool]:
        return (a ^ b ^ c , (a & b) | (a & c) | (b & c))
