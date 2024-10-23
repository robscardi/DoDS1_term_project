library ieee;
use ieee.std_logic_1164.all;

package pwr_message_type is
    type pwr_message_array is array (0 to 6) of STD_ULOGIC_VECTOR(255 downto 0);
end package pwr_message_type;