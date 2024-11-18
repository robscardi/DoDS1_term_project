LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;

ENTITY mod_mult_1_tb_synth IS
END mod_mult_1_tb_synth;

ARCHITECTURE projecttb OF mod_mult_1_tb_synth IS
    
    CONSTANT CLOCK_PERIOD : TIME := 10 ns;
    CONSTANT input_width : POSITIVE := 256;
    CONSTANT scenario_length : POSITIVE := 2;
    CONSTANT RESET_TIME     : TIME := 2*CLOCK_PERIOD;

    type num_array is array (natural range<>) of integer;

    SIGNAL tb_rst   : STD_LOGIC := '1';
    SIGNAL tb_clk   : STD_LOGIC := '0';
    
    signal tb_input_a  : STD_LOGIC_VECTOR(input_width-1 downto 0) := (others => '0');
    signal tb_input_b  : STD_LOGIC_VECTOR(input_width-1 downto 0) := (others => '0');
    signal tb_modulus  : STD_LOGIC_VECTOR(input_width-1 downto 0) := (others => '0');

    signal tb_mod_res  : STD_LOGIC_VECTOR(input_width-1 downto 0) := (others => '0');

    signal tb_enable_i     : STD_LOGIC := '0';
    signal tb_output_valid : STD_LOGIC := '0';

    -- SCENARIO SIGNALS
    signal input_a_scenario     : num_array(scenario_length-1 downto 0) := ( 0 => 3649, 1 => 2345);
    signal input_b_scenario     : num_array(scenario_length-1 downto 0) := ( 0 => 2753, 1 => 8493 );
    signal input_mod_scenario   : num_array(scenario_length-1 downto 0) := ( 0 => 28097, 1 => 13984);

begin

    PROC_CLK : process is
    begin
        WAIT FOR CLOCK_PERIOD/2;
        tb_clk <= NOT tb_clk;
    end process;

    UUT : entity work.modulus_multiplication 
        port map (
            clk => tb_clk,
            reset_n => tb_rst,

            enable_i => tb_enable_i,
            input_a => tb_input_a,
            input_b => tb_input_b,
            modulus => tb_modulus,
            
            output => tb_mod_res,
            output_ready => tb_output_valid
        );

    RESET_PROC : process is
    begin
        wait for RESET_TIME;
        tb_rst <= '0';
        wait for 2*CLOCK_PERIOD;
        tb_rst <= '1';
        wait;

    end process;

    TEST_ROUTINE : process is
        variable correct_res : unsigned(input_width-1 downto 0) := TO_UNSIGNED(0, input_width);
    begin

        WAIT UNTIL tb_rst = '1';
        
                    -- extra manual test
        WAIT UNTIL rising_edge(tb_clk);
        tb_input_a <= x"76e38fd657e8b6db8f7d173f2cc198a5cd02657c45d264c8629015c4b22ec17e";
        tb_input_b <= x"76e38fd657e8b6db8f7d173f2cc198a5cd02657c45d264c8629015c4b22ec17e";
        tb_modulus <= x"b0f76b9c82af81aaf51f3dc145c3faf5c40841144b4772616411aa362640f1ce";

        tb_enable_i <= '1';
        WAIT UNTIL rising_edge(tb_clk);
        tb_enable_i <= '0';
        WAIT UNTIL tb_output_valid = '1';
        assert tb_mod_res = x"4af2b939936c08bcf01fe032cb9e930dac5517ad2b8428ec5e60cd50735b9e60"
            report "FAILED AT LAST ITERATION \n" &  " UUT result: " & positive'image(to_integer(unsigned(tb_mod_res))) & "\n CORRECT result: 4af2b939936c08bcf01fe032cb9e930dac5517ad2b8428ec5e60cd50735b9e60"
            severity failure;

        
        for i in  scenario_length-1 downto 0 loop
            WAIT UNTIL rising_edge(tb_clk);
            tb_input_a <= STD_LOGIC_VECTOR(TO_UNSIGNED(input_a_scenario(i), input_width));
            tb_input_b <= STD_LOGIC_VECTOR(TO_UNSIGNED(input_b_scenario(i), input_width));
            tb_modulus <= STD_LOGIC_VECTOR(TO_UNSIGNED(input_mod_scenario(i), input_width));
            tb_enable_i <= '1';
            WAIT UNTIL rising_edge(tb_clk);
            tb_enable_i <= '0';
            WAIT UNTIL tb_output_valid = '1';
            correct_res := TO_UNSIGNED((input_a_scenario(i) * input_b_scenario(i)) mod input_mod_scenario(i), input_width);
            assert tb_mod_res = STD_LOGIC_VECTOR(correct_res)
                report "FAILED AT ITERATION " & integer'image(i) &  " UUT result: " & integer'image(to_integer(unsigned(tb_mod_res))) & "\n CORRECT result: " & integer'image(to_integer(correct_res))
                severity failure;
        end loop;

        WAIT UNTIL rising_edge(tb_clk);
        assert false report "TEST SUCCESSFULL" severity failure;
    end process;
end projecttb;