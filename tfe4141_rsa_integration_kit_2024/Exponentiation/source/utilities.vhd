library ieee;
use ieee.std_logic_1164.all;

package pwr_message_type is
    type pwr_message_array is array (0 to 6) of STD_ULOGIC_VECTOR(255 downto 0);
end package pwr_message_type;

package fsm is
    type state is (IDLE, PRECALC1, PRECALC2, PRECALC3, PRECALC4, PRECALC5, PRECALC6, PRECALC7, SQUARE1, SQUARE2, SQUARE3, MULTIPLY, DONE);
end package fsm;

library ieee;
use ieee.std_logic_1164.all;
package data_type is
    subtype DATA is STD_ULOGIC_VECTOR;
    type FIFO is array (natural range <>) of STD_ULOGIC_VECTOR;
end package data_type;