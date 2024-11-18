LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;

ENTITY mod_mult_2_tb IS
END mod_mult_2_tb;

ARCHITECTURE projecttb OF mod_mult_2_tb IS
    
    CONSTANT CLOCK_PERIOD : TIME := 10 ns;
    CONSTANT input_width : POSITIVE := 256;
    CONSTANT RESET_TIME     : TIME := 2*CLOCK_PERIOD;

    SIGNAL tb_rst   : STD_ULOGIC := '1';
    SIGNAL tb_clk   : STD_ULOGIC := '0';
    
    signal tb_input_a  : STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0');
    signal tb_input_b  : STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0');
    signal tb_modulus  : STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0');

    signal tb_mod_res  : STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0');

    signal tb_enable_i     : STD_ULOGIC := '0';
    signal tb_output_valid : STD_ULOGIC := '0';

    file input_file: text open read_mode is "modulus_multiplication_2_tb.txt";
    
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
        variable line_in : line;
        variable line_blank  : line;
        variable var_tb_mod     : STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0'); 
        variable var_tb_a       : STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0'); 
        variable var_tb_b       : STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0');
        variable var_tb_result  : STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0');
        variable i : INTEGER := 0; 
    begin
        WAIT UNTIL tb_rst = '1';
        
        readline(input_file, line_in);
        hread(line_in, var_tb_mod);
        tb_modulus <= var_tb_mod;

        while not ENDFILE(input_file) loop
            WAIT UNTIL rising_edge(tb_clk);

            readline(input_file, line_blank);             -- Read blanck line
            
            readline(input_file, line_in);
            hread(line_in, var_tb_a);
            readline(input_file, line_in);
            hread(line_in, var_tb_b);

            tb_input_a <= var_tb_a;
            tb_input_b <= var_tb_b;
            tb_enable_i <= '1';
            WAIT UNTIL rising_edge(tb_clk);
            tb_enable_i <= '0';
            WAIT UNTIL tb_output_valid = '1';
            
            readline(input_file, line_in);
            hread(line_in, var_tb_result);
            i := i+1;

            assert tb_mod_res = var_tb_result
                report "FAILED AT ITERATION " & integer'image(i) &  " UUT result: " & integer'image(to_integer(unsigned(tb_mod_res))) & "\n CORRECT result: " & integer'image(to_integer(correct_res))
                severity failure;
        end loop;
        WAIT UNTIL rising_edge(tb_clk);
        assert false report "TEST SUCCESSFULL" severity failure;
    end process;
end projecttb;