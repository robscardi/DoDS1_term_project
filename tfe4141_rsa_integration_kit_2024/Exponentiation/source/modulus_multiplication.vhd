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

        enable_i        : in STD_ULOGIC;
        input_a         : in STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
        input_b         : in STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
        modulus         : in STD_ULOGIC_VECTOR(C_block_size-1 downto 0);

        output          : out STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
        output_ready    : out STD_ULOGIC
    );
end modulus_multiplication;


architecture blakley_serial of modulus_multiplication is
    signal partial_res          : STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
    signal partial_sum          : STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
    signal mod_res              : STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
    signal counter              : unsigned(log2c(C_BLOCK_SIZE) downto 0);
    signal a_r                  : STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
    signal b_r                  : STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
    signal is_active            : STD_ULOGIC;
    
    component blakley_mod
        generic(C_BLOCK_SIZE : INTEGER);
        port(
            input       : in    STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
            modulus     : in    STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
            output      : out   STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0)
        );
    end component;
begin

MOD_1 : blakley_mod
    generic map (
        C_BLOCK_SIZE => C_block_size
    )
    port map(
        input => partial_sum,
        modulus => modulus,
        output => mod_res
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


COUNTER_PROC : process (clk, reset_n, enable_i)
begin
    if(reset_n = '0' or enable_i = '1' ) then
        counter <= (others => '0');
    elsif(rising_edge(clk)) then
        if (is_active = '1') then
            counter <= counter + 1;
        else 
            counter <= (others => '0');
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
        else
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
    else
        if (a_r(0) = '1') then
            partial_sum <= STD_LOGIC_VECTOR(shift_left(unsigned(partial_res),1) + unsigned(b_r));
        else
            partial_sum <= STD_LOGIC_VECTOR(shift_left(unsigned(partial_res),1)); 
        end if;
        partial_res <= mod_res;
    end if;
end process;


end blakley_serial;
