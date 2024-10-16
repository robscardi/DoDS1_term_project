LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;



ENTITY project_tb IS
END project_tb;

ARCHITECTURE projecttb OF project_tb IS
    
    CONSTANT CLOCK_PERIOD : TIME := 10 ns;
    CONSTANT input_width : POSITIVE := 256;
    CONSTANT scenario_length : POSITIVE := 2;
    CONSTANT RESET_TIME     : TIME := 2*CLOCK_PERIOD;

    type num_array is array (natural range<>) of integer;

    SIGNAL tb_rst   : STD_ULOGIC := '1';
    SIGNAL tb_clk   : STD_ULOGIC := '0';
    
    signal tb_input_a  : STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0');
    signal tb_input_b  : STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0');
    signal tb_modulus  : STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0');

    signal tb_mod_res  : STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0');

    signal tb_enable_i     : STD_ULOGIC := '0';
    signal tb_output_valid : STD_ULOGIC := '0';

    -- SCENARIO SIGNALS
    signal input_a_scenario     : num_array(scenario_length-1 downto 0) := ( 0 => 3649, 1 => 2345);
    signal input_b_scenario     : num_array(scenario_length-1 downto 0) := ( 0 => 2753, 1 => 8493 );
    signal input_mod_scenario   : num_array(scenario_length-1 downto 0) := ( 0 => 28097, 1 => 13984);

    component modulus_multiplication is
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
    end component;

begin

    PROC_CLK : process is
    begin
        WAIT FOR CLOCK_PERIOD/2;
        tb_clk <= NOT tb_clk;
    end process;

    UUT : modulus_multiplication 
        generic map (
            C_block_size => input_width
        )
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
        for i in  scenario_length-1 to 0 loop
            WAIT UNTIL rising_edge(tb_clk);
            tb_input_a <= STD_ULOGIC_VECTOR(TO_UNSIGNED(input_a_scenario(i), input_width));
            tb_input_b <= STD_ULOGIC_VECTOR(TO_UNSIGNED(input_b_scenario(i), input_width));
            tb_modulus <= STD_ULOGIC_VECTOR(TO_UNSIGNED(input_mod_scenario(i), input_width));
            tb_enable_i <= '1';
            WAIT UNTIL rising_edge(tb_clk);
            tb_enable_i <= '0';
            WAIT UNTIL tb_output_valid = '1';
            correct_res := TO_UNSIGNED((input_a_scenario(i) * input_b_scenario(i)) mod input_mod_scenario(i), input_width);
            assert tb_mod_res = STD_ULOGIC_VECTOR(correct_res)
                report "FAILED AT ITERATION " & integer'image(i) &  " UUT result: " & integer'image(to_integer(unsigned(tb_mod_res))) & "\n CORRECT result: " & integer'image(to_integer(correct_res))
                severity failure;
        end loop;
        WAIT UNTIL rising_edge(tb_clk);
        assert false report "TEST SUCCESSFULL" severity failure;
    end process;
end projecttb;