
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_utilities.all;

entity blakley_mod is 
    generic(
        C_BLOCK_SIZE : integer := 256
    );
    port (

        clk             : in STD_ULOGIC;
        reset_n         : in STD_ULOGIC;

        enable_i        : in STD_ULOGIC;
        input           : in STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
        modulus         : in STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);

        output          : out STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
        output_ready    : out STD_ULOGIC

    );
end blakley_mod;

architecture bhv of blakley_mod is
begin
    
    MAIN_PROC : process (clk, reset_n, input, modulus)
        variable first_sub      : signed(C_BLOCK_SIZE downto 0 );
        variable second_sub     : signed(C_BLOCK_SIZE downto 0 );
    begin
        first_sub   := signed('0' & input) - signed('0' & modulus);
        second_sub  := signed('0' & input) - signed('0' & shift_left(unsigned(modulus), 1)); 
        
        if(reset_n = '0') then
            output <= (others => '0');
            output_ready <= '0';

        elsif (rising_edge(clk)) then
            if(enable_i = '1') then
                if (first_sub(C_BLOCK_SIZE) = '1') then
                    output <= input;
                    output_ready <= '1';
                elsif(second_sub(C_BLOCK_SIZE) = '1') then
                    output <= STD_ULOGIC_VECTOR(first_sub(C_BLOCK_SIZE-1 downto 0));
                    output_ready <= '1';
                else
                    output <= STD_ULOGIC_VECTOR(second_sub(C_BLOCK_SIZE-1 downto 0));
                    output_ready <= '1';
                end if;
            else
                output <= (others => '0');
                output_ready <= '0';
            end if;
        end if;
    end process;
    
    
end architecture;