library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity exponentiation_tb is
end exponentiation_tb;

architecture test of exponentiation_tb is
    type state is (IDLE, PRECALC1, PRECALC2, PRECALC3, PRECALC4, PRECALC5, PRECALC6, PRECALC7, SQUARE1, SQUARE2, SQUARE3, MULTIPLY, DONE);
    constant C_block_size : integer := 256;
    CONSTANT CLOCK_PERIOD : TIME := 10 ns;
    
    -- Input signals to DUT
    signal tb_valid_in     : std_ulogic := '0';
    signal tb_ready_in     : std_ulogic;
    signal tb_message      : std_ulogic_vector(C_block_size-1 downto 0) := (others => '0');
    signal tb_key          : std_ulogic_vector(C_block_size-1 downto 0) := (others => '0');
    signal tb_modulus      : std_ulogic_vector(C_block_size-1 downto 0) := (others => '0');

    -- Output signals from DUT
    signal tb_ready_out    : std_ulogic := '1';
    signal tb_valid_out    : std_ulogic;
    signal tb_result       : std_ulogic_vector(C_block_size-1 downto 0);

    -- Clock and Reset
    signal tb_clk          : std_ulogic := '0';
    signal tb_reset_n      : std_ulogic := '1';
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.exponentiation
--        generic map (
--            C_block_size => C_block_size
--        )
        port map (
            valid_in    => tb_valid_in,
            ready_in    => tb_ready_in,
            message     => tb_message,
            key         => tb_key,
            ready_out   => tb_ready_out,
            valid_out   => tb_valid_out,
            result      => tb_result,
            modulus     => tb_modulus,
            clk         => tb_clk,
            reset_n     => tb_reset_n
        );

    -- Clock process
    PROC_CLK : process is
    begin
        WAIT FOR CLOCK_PERIOD/2;
        tb_clk <= NOT tb_clk;
    end process;
    
    -- Stimulus process
    Stimulus : process
            variable correct_res : unsigned(C_block_size-1 downto 0) := (others => '0');
    begin
        -- Initialize inputs
        tb_reset_n <= '0';   
        wait for 2*CLOCK_PERIOD;   
        tb_reset_n <= '1';   
        wait for CLOCK_PERIOD;
        
        --Use hexadecimal writing to represent large numbers
        tb_message <= x"045ccbeea1f34185c93d9a08bed7f95b54155c689b9e07e176436811e28ca894";
        tb_key <= x"123d8009581fcb68bb3c23f5ee33a3ef2a59080d73e0f9a97a2eee84daa7a960";
        tb_modulus <= x"2130ffe07897762cc37a9c7d5268559f4b0a6b9d3329d8bb1713ee8ab6cf91c7";
        wait for CLOCK_PERIOD;
        
        assert unsigned(tb_message) < unsigned(tb_modulus) 
            report "MESSAGE SHOULD BE SMALLER THAN MODULUS" severity failure;
        assert unsigned(tb_key) < unsigned(tb_modulus)
            report "KEY SHOULD BE SMALLER THAN MODULUS" severity failure;
            
        tb_valid_in <= '1';
        WAIT UNTIL tb_valid_out = '1';
        tb_valid_in <= '0';
        
        --Compute correct result with Python using pow(message,key,modulus)
        correct_res := x"13df3bb55f156c1354ce75d743b1ce34cf4c64c7eb35c2870aa2517a7e088a2a";
        assert tb_result = std_ulogic_vector(correct_res)
            report "TEST FAILED" severity failure;
        WAIT UNTIL rising_edge(tb_clk);
        assert false report "TEST SUCCESSFUL" severity failure;
    end process;

end test;
