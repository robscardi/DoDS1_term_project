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
    signal partial_sum          : STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
    signal partial_sum_ready    : STD_ULOGIC;

    signal mod_res              : STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
    signal partial_res_ready    : STD_ULOGIC;

    signal counter              : unsigned(log2c(C_BLOCK_SIZE) downto 0);
    signal a_r                  : STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
    signal b_r                  : STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
    signal is_active            : STD_ULOGIC;

    signal blakley_mod_ready       : STD_ULOGIC;
    
    pure function module_blakley (input: STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0); modulus: STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0) ) return STD_ULOGIC_VECTOR is

        variable first_sub      : signed(C_BLOCK_SIZE downto 0 );
        variable second_sub     : signed(C_BLOCK_SIZE downto 0 );

    begin
        first_sub   := signed('0' & input) - signed('0' & modulus);
        second_sub  := signed('0' & input) - signed('0' & shift_left(unsigned(modulus), 1)); 
        
                if (first_sub(C_BLOCK_SIZE) = '1') then
                    return input;
                elsif(second_sub(C_BLOCK_SIZE) = '1') then
                    return STD_ULOGIC_VECTOR(first_sub(C_BLOCK_SIZE-1 downto 0));
                else
                    return STD_ULOGIC_VECTOR(second_sub(C_BLOCK_SIZE-1 downto 0));
                end if;
    end function;
    
    component blakley_mod
        generic(C_BLOCK_SIZE : INTEGER);
        port(
            clk             : in STD_ULOGIC;
            reset_n         : in STD_ULOGIC;

            enable_i        : in    STD_ULOGIC;

            input           : in    STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
            modulus         : in    STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
            output          : out   STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);

            output_ready    : out   STD_ULOGIC
        );
    end component;
begin

MOD_1 : blakley_mod
    generic map (
        C_BLOCK_SIZE => C_block_size
    )
    port map(
        clk => clk,
        reset_n => reset_n,

        enable_i => partial_sum_ready,

        input => partial_sum,
        modulus => modulus,
        output => mod_res,

        output_ready => blakley_mod_ready
    );

READY_PROC : process (clk, reset_n, counter)
begin
    if(reset_n = '0') then
        output_ready <= '0';
        output <= (others => '0');
    elsif(rising_edge(clk)) then
        if (counter = C_BLOCK_SIZE - 1) then
            output_ready <= '1';
            output <= partial_res;
        else
            output_ready <= '0';
            output <= (others => '0');
        end if; 
    end if;
end process;


COUNTER_PROC : process (partial_sum_ready, partial_res_ready, reset_n, enable_i)
begin
    if(reset_n = '0' or enable_i = '1' ) then
        counter <= (others => '0');
    elsif(rising_edge(partial_sum_ready)) then
        if (is_active = '1' and partial_sum_ready = '1') then
            counter <= counter + 1;
        elsif (is_active = '0') then
            counter <= (others => '0');
        else 
            counter <= counter;
        end if;
    end if;
end process;

SHIFT_A_PROC : process (clk, reset_n, enable_i)
begin
    if(reset_n = '0') then
        a_r <= (others => '0');
        b_r <= (others => '0');
    elsif(rising_edge(clk)) then
        if(enable_i = '1') then
            a_r <= input_a;
            b_r <= input_b;
        elsif(partial_sum_ready = '1') then
            a_r <= STD_ULOGIC_VECTOR(SHIFT_RIGHT(unsigned(a_r), 1));
        end if;
    end if;
end process;

IS_ACTIVE_PROC : process (clk, reset_n, enable_i)
begin
    if( reset_n = '0' or counter = C_BLOCK_SIZE-1) then
        is_active <= '0';
    elsif(rising_edge(clk) and enable_i = '1') then
        is_active <= '1';
    end if;
end process;


PARTIAL_SUM_PROC : process ( clk, reset_n, counter)
begin
    if(reset_n = '0') then
        partial_res <= (others => '0');
        partial_sum <= (others => '0');
        partial_res_ready <= '0';
        partial_sum_ready <= '0';
    elsif (rising_edge(clk)) then
        if((partial_res_ready = '1' or counter = 0) and is_active = '1') then
            if (a_r(0) = '1') then
                partial_sum <= STD_LOGIC_VECTOR(shift_left(unsigned(partial_res),1) + unsigned(b_r));
            else
                partial_sum <= STD_LOGIC_VECTOR(shift_left(unsigned(partial_res),1)); 
            end if;
            partial_sum_ready <= '1';
        else 
            partial_sum_ready <= '0';
        end if;
        partial_res_ready <= blakley_mod_ready;
        partial_res <= mod_res;
    end if;
end process;


end blakley_serial;
