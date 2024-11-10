library ieee;
use ieee.std_logic_1164.all;

library ieee;
use ieee.std_logic_1164.all;
package data_type is
    subtype DATA is STD_ULOGIC_VECTOR;
    type FIFO is array (natural range <>) of STD_ULOGIC_VECTOR;
end package data_type;