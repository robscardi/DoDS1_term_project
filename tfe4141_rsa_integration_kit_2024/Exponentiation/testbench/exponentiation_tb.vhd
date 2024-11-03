library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_exponentiation is
end tb_exponentiation;

architecture test of tb_exponentiation is
    constant C_block_size : integer := 256;
    -- Input signals to DUT
    signal valid_in     : std_ulogic;
    signal ready_in     : std_ulogic;
    signal message      : std_ulogic_vector(C_block_size-1 downto 0);
    signal key          : std_ulogic_vector(C_block_size-1 downto 0);
    signal modulus      : std_ulogic_vector(C_block_size-1 downto 0);

    -- Output signals from DUT
    signal ready_out    : std_ulogic := '1';
    signal valid_out    : std_ulogic;
    signal result       : std_ulogic_vector(C_block_size-1 downto 0);

    -- Clock and Reset
    signal clk          : std_ulogic := '0';
    signal reset_n      : std_ulogic := '1';
    
    signal int_message : integer := 19;
    signal int_key : integer := 3062;
    signal int_modulus : integer := 2359;

    
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
    
    process
begin
    --wait until result /= (others => '0');
    wait until valid_out = '1';
    report "Simulation stopped: valid_out = '1'" severity note;
    std.env.stop;  -- Stop the simulation
end process;

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
--        int_message <= 19;
--        int_key <= 27;
--        int_modulus <= 41;
        
        message <= to_stdulogic_vector_256(int_message);
        key <= to_stdulogic_vector_256(int_key);
        modulus <= to_stdulogic_vector_256(int_modulus);
        
        -- Wait for result
        wait for 500 ns;

        -- End simulation
        wait;
    end process;

end test;
