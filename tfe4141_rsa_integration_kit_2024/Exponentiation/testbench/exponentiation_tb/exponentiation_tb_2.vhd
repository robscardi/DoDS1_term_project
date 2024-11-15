library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity exponentiation_2_tb is
end exponentiation_2_tb;

architecture test of exponentiation_2_tb is
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
    constant key_e : STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0) := x"0000000000000000000000000000000000000000000000000000000000010001";
    constant key_d : STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0) := x"0cea1651ef44be1f1f1476b7539bed10d73e3aac782bd9999a1e5a790932bfe9";
    constant key_n : STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0) := x"99925173ad65686715385ea800cd28120288fc70a9bc98dd4c90d676f8ff768d";
    constant mess  : STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0) := x"8888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff";
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
            variable intermediate : STD_ULOGIC_VECTOR(c_block_size-1 downto 0) := (others => '0'); 
    begin
        -- Initialize inputs
        tb_reset_n <= '0';   
        wait for 2*CLOCK_PERIOD;   
        tb_reset_n <= '1';   
        wait for CLOCK_PERIOD;
        
        --Use hexadecimal writing to represent large numbers
        tb_message <= mess;
        tb_key <= key_e;
        tb_modulus <= key_n;
        wait for CLOCK_PERIOD;
        
        assert unsigned(tb_message) < unsigned(tb_modulus) 
            report "MESSAGE SHOULD BE SMALLER THAN MODULUS" severity failure;
        assert unsigned(tb_key) < unsigned(tb_modulus)
            report "KEY SHOULD BE SMALLER THAN MODULUS" severity failure;
            
        tb_valid_in <= '1';
        WAIT UNTIL tb_valid_out = '1';
        intermediate := tb_result;
        tb_valid_in <= '0';
        wait until rising_edge(tb_clk);
        tb_message <= intermediate;
        tb_key <= key_d;
        report "intermediate : " & integer'image(to_integer(unsigned(intermediate))) severity NOTE;
        assert unsigned(tb_message) < unsigned(tb_modulus) 
            report "MESSAGE SHOULD BE SMALLER THAN MODULUS" severity failure;
        assert unsigned(tb_key) < unsigned(tb_modulus)
            report "KEY SHOULD BE SMALLER THAN MODULUS" severity failure;

        --Compute correct result with Python using pow(message,key,modulus)
        correct_res := UNSIGNED(mess);
        assert tb_result = std_ulogic_vector(correct_res)
            report "TEST FAILED : result = " & INTEGER'image(to_integer(unsigned(tb_result))) & " correct = " & INTEGER'image(to_integer(unsigned(mess)))  severity failure;
        WAIT UNTIL rising_edge(tb_clk);
        assert false report "TEST SUCCESSFUL" severity failure;
    end process;

end test;
