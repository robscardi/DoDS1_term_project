library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pwr_message_type.all;  -- Assuming pwr_message_type is defined elsewhere

entity tb_exponentiation is
end tb_exponentiation;

architecture test of tb_exponentiation is
    constant C_block_size : integer := 256;

    -- Input signals to DUT
    signal valid_in     : std_ulogic := '0';
    signal ready_in     : std_ulogic := '1';
    signal message      : std_ulogic_vector(C_block_size-1 downto 0);
    signal key          : std_ulogic_vector(C_block_size-1 downto 0);
    signal pwr_message  : pwr_message_array;  -- Assuming correct type
    signal modulus      : std_ulogic_vector(C_block_size-1 downto 0);

    -- Output signals from DUT
    signal ready_out    : std_ulogic;
    signal valid_out    : std_ulogic;
    signal result       : std_ulogic_vector(C_block_size-1 downto 0);

    -- Clock and Reset
    signal clk          : std_ulogic := '0';
    signal reset_n      : std_ulogic := '1';

    -- Clock period
    constant clk_period : time := 10 ns;
    
        function to_stdulogic_vector_256(num : integer) return std_ulogic_vector is
        variable result : std_ulogic_vector(255 downto 0);
    begin
        result := std_ulogic_vector(to_unsigned(num, 256));
        return result;
    end function;

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.exponentiation
        generic map (
            C_block_size => C_block_size
        )
        port map (
            valid_in    => valid_in,
            ready_in    => ready_in,
            message     => message,
            key         => key,
            pwr_message => pwr_message,
            ready_out   => ready_out,
            valid_out   => valid_out,
            result      => result,
            modulus     => modulus,
            clk         => clk,
            reset_n     => reset_n
        );

    -- Clock process
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process clk_process;

    -- Stimulus process
    stimulus : process
    begin
        -- Initialize inputs
        
        reset_n <= '0';   -- Apply reset
        wait for 20 ns;   -- Hold reset for some time
        reset_n <= '1';   -- Release reset

        -- Apply first test case
        wait for 10 ns;
        valid_in <= '1';
        message <= (others => '0');  
        message(2) <= '1';              --base = 4
        key <= (others => '0');      
        key(4 downto 0) <= "10010";             -- exponent = 18
        modulus <= (others => '0');  
        modulus(4 downto 0) <= "11101";  -- modulus = 29
        pwr_message(0) <= to_stdulogic_vector_256(4**1);
        pwr_message(1) <= to_stdulogic_vector_256(4**2);
        pwr_message(2) <= to_stdulogic_vector_256(4**3);
        pwr_message(3) <= to_stdulogic_vector_256(4**4);
        pwr_message(4) <= to_stdulogic_vector_256(4**5);
        pwr_message(5) <= to_stdulogic_vector_256(4**6);
        pwr_message(6) <= to_stdulogic_vector_256(4**7);
        -- Wait for result
        wait for 500 ns;

        -- End simulation
        wait;
    end process;

end test;
