library ieee;
use ieee.std_logic_1164.all;

library ieee;
use ieee.std_logic_1164.all;
package data_type is
    subtype DATA is STD_ULOGIC_VECTOR;
    type FIFO is array (natural range <>) of STD_ULOGIC_VECTOR;
    type state is (IDLE, PRECALC1, PRECALC2, PRECALC3, PRECALC4, PRECALC5, PRECALC6, PRECALC7, SQUARE1, SQUARE2, SQUARE3, MULTIPLY, DONE);
end package data_type;