LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;

ENTITY mod_exp_1_tb IS
END mod_exp_1_tb;

ARCHITECTURE projecttb OF mod_exp_1_tb IS
    
    CONSTANT CLOCK_PERIOD : TIME := 10 ns;
    CONSTANT input_width : POSITIVE := 256;
    CONSTANT scenario_length : POSITIVE := 2;
    CONSTANT RESET_TIME     : TIME := 2*CLOCK_PERIOD;
    

    type num_array is array (natural range<>) of integer;

    SIGNAL tb_rst   : STD_ULOGIC := '1';
    SIGNAL tb_clk   : STD_ULOGIC := '0';
    
    signal tb_input_m  : STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0');
    signal tb_input_k  : STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0');
    signal tb_modulus  : STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0');

    signal tb_mod_res  : STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0');

    signal tb_valid_in  : STD_ULOGIC;
    signal tb_ready_in : STD_ULOGIC;
    signal tb_valid_out : STD_ULOGIC;
    signal tb_ready_out : STD_ULOGIC;

    -- SCENARIO SIGNALS
    signal input_m_scenario     : num_array(scenario_length-1 downto 0) := ( 0 => 3649, 1 => 2345);
    signal input_k_scenario     : num_array(scenario_length-1 downto 0) := ( 0 => 2753, 1 => 8493 );
    signal input_mod_scenario   : num_array(scenario_length-1 downto 0) := ( 0 => 28097, 1 => 13984);

    component vlnw_exponentiation is
        port (
            --input controll
            valid_in	: in STD_ULOGIC;
            ready_in	: out STD_ULOGIC;
    
            --input data
            message 	: in STD_ULOGIC_VECTOR ( input_width-1 downto 0 );
            key 		: in STD_ULOGIC_VECTOR ( input_width-1 downto 0 );
    
            --ouput controll
            ready_out	: in STD_ULOGIC;
            valid_out	: out STD_ULOGIC;
    
            --output data
            result 		: out STD_ULOGIC_VECTOR(input_width-1 downto 0);
    
            --modulus
            modulus 	: in STD_ULOGIC_VECTOR(input_width-1 downto 0);
    
            --utility
            clk 		: in STD_ULOGIC;
            reset_n 	: in STD_ULOGIC
        );
    
    end component;

begin

    PROC_CLK : process is
    begin
        WAIT FOR CLOCK_PERIOD/2;
        tb_clk <= NOT tb_clk;
    end process;

    UUT : entity work.vlnw_exponentiation
     port map(
        valid_in => tb_valid_in,
        ready_in => tb_ready_in,
        message => tb_input_m,
        key => tb_input_k,
        ready_out => tb_ready_out,
        valid_out => tb_valid_out,
        result => tb_mod_res,
        modulus => tb_input_m,
        clk => tb_clk,
        reset_n => tb_rst
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
        tb_ready_out <= '1';
        WAIT UNTIL tb_rst = '1';
        for i in  scenario_length-1 downto 0 loop
            WAIT UNTIL rising_edge(tb_clk);
            tb_input_m <= STD_ULOGIC_VECTOR(TO_UNSIGNED(input_m_scenario(i), input_width));
            tb_input_k <= STD_ULOGIC_VECTOR(TO_UNSIGNED(input_k_scenario(i), input_width));
            tb_modulus <= STD_ULOGIC_VECTOR(TO_UNSIGNED(input_mod_scenario(i), input_width));
            tb_valid_in <= '1';
            WAIT UNTIL rising_edge(tb_clk);
            tb_valid_in <= '0';
            WAIT UNTIL tb_valid_out = '1';
            correct_res := TO_UNSIGNED((input_m_scenario(i) ** input_k_scenario(i)) mod input_mod_scenario(i), input_width);
            assert tb_mod_res = STD_ULOGIC_VECTOR(correct_res)
                report "FAILED AT ITERATION " & integer'image(i) &  " UUT result: " & integer'image(to_integer(unsigned(tb_mod_res))) & "\n CORRECT result: " & integer'image(to_integer(correct_res))
                severity failure;
        end loop;
        WAIT UNTIL rising_edge(tb_clk);
        assert false report "TEST SUCCESSFULL" severity failure;
    end process;
end projecttb;