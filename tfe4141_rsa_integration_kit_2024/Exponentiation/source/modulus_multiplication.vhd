library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_utilities.all;

entity modulus_multiplication is
    generic(
        C_block_size : integer := 256
    );
    port(
        clk             : in STD_ULOGIC;
        reset_n         : in STD_ULOGIC;

        enable_i            : in STD_ULOGIC;
        input_a             : in STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
        input_b             : in STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
        modulus             : in STD_ULOGIC_VECTOR(C_block_size-1 downto 0);

        output          : out STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
        output_ready    : out STD_ULOGIC
    );
end modulus_multiplication;


architecture blakley_serial of modulus_multiplication is
    signal partial_res          : STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
    signal partial_sum          : STD_ULOGIC_VECTOR(C_BLOCK_SIZE+1 downto 0);
    signal partial_sum_ready    : STD_ULOGIC;

    signal partial_res_ready    : STD_ULOGIC;
    signal counter_middle       : STD_ULOGIC;

    signal counter              : unsigned(log2c(C_BLOCK_SIZE)+1 downto 0);
    signal a_r                  : STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
    signal b_r                  : STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
    signal is_active            : STD_ULOGIC;

    
    pure function module_blakley (input: STD_ULOGIC_VECTOR(C_BLOCK_SIZE+1 downto 0); modulus: STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0) ) return STD_ULOGIC_VECTOR is

        variable first_sub      : signed(C_BLOCK_SIZE+2 downto 0 );
        variable second_sub     : signed(C_BLOCK_SIZE+2 downto 0 );

    begin
        first_sub   := signed('0' & input) - signed("000" & modulus);
        second_sub  := signed('0' & input) - signed("00" & modulus & '0'); 
        
                if (first_sub(C_BLOCK_SIZE+2) = '1') then
                    return input(C_BLOCK_SIZE-1 downto 0);
                elsif(second_sub(C_BLOCK_SIZE+2) = '1') then
                    return STD_ULOGIC_VECTOR(first_sub(C_BLOCK_SIZE-1 downto 0));
                else
                    return STD_ULOGIC_VECTOR(second_sub(C_BLOCK_SIZE-1 downto 0));
                end if;
    end function;
    
begin

READY_PROC : process (clk, reset_n, counter)
begin
    if(reset_n = '0') then
        output_ready <= '0';
        output <= (others => '0');
    elsif(rising_edge(clk)) then
        if (counter = C_BLOCK_SIZE+1) then
            output_ready <= '1';
            output <= partial_res;
        else
            output_ready <= '0';
            output <= (others => '0');
        end if; 
    end if;
end process;


COUNTER_PROC : process (clk, partial_sum_ready, partial_res_ready, reset_n, enable_i)
begin
    if(reset_n = '0' or enable_i = '1' ) then
        counter <= (others => '0');
        counter_middle <= '0';
    elsif(rising_edge(clk)) then
        if (is_active = '1' and partial_res_ready = '1') then
            counter <= counter + 1;
            counter_middle <= '0';
        elsif(is_active = '1') then 
            counter <= counter;
            counter_middle <= '1';
        end if;
    end if;
end process;

SHIFT_A_PROC : process (clk, reset_n, enable_i, partial_sum_ready)
begin
    if(reset_n = '0') then
        a_r <= (others => '0');
        b_r <= (others => '0');
    elsif(rising_edge(clk)) then
        if(enable_i = '1') then
            a_r <= input_a;
            b_r <= input_b;
        elsif(is_active = '1' and partial_sum_ready = '1') then
            a_r <= STD_ULOGIC_VECTOR(shift_left(unsigned(a_r), 1));
        end if;
    end if;
end process;

IS_ACTIVE_PROC : process (clk, reset_n, enable_i)
begin
    if( reset_n = '0' or counter = C_BLOCK_SIZE+1) then
        is_active <= '0';
    elsif(rising_edge(clk) and enable_i = '1') then
        is_active <= '1';
    end if;
end process;

PARTIAL_SUM_PROC : process ( clk, reset_n, counter)
begin
    if(reset_n = '0' or enable_i = '1')  then
        partial_res <= (others => '0');
        partial_sum <= (others => '0');
        partial_res_ready <= '1';
        partial_sum_ready <= '0';
    elsif (rising_edge(clk)) then
        if(partial_res_ready = '1' and is_active = '1') then
            if (a_r(C_BLOCK_SIZE-1) = '1') then
                partial_sum <= STD_ULOGIC_VECTOR(unsigned('0' & partial_res & '0') + unsigned("00" & b_r));
            else
                partial_sum <= '0' & partial_res & '0'; 
            end if;
            partial_sum_ready <= '1';
            partial_res_ready <= '0';
        elsif(partial_sum_ready = '1') then 
            partial_res <= module_blakley(partial_sum, modulus);
            partial_res_ready <= '1';
            partial_sum_ready <= '0';
        end if;
    end if;
end process;
end blakley_serial;
