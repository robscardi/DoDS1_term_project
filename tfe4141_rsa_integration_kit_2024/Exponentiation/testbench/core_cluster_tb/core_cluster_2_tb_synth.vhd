LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;
use work.data_type.all;

ENTITY core_cluster_2_tb_synth IS
END core_cluster_2_tb_synth;

ARCHITECTURE bhvtb OF core_cluster_2_tb_synth IS
    
    CONSTANT CLOCK_PERIOD : TIME := 10 ns;
    CONSTANT input_width : POSITIVE := 256;
    CONSTANT RESET_TIME     : TIME := 2*CLOCK_PERIOD;

    type FIFO is array (40 downto 0) of STD_ULOGIC_VECTOR(input_width-1 downto 0);
    signal tb_result_check_fifo : FIFO := (others => (others => '0') ); 

    SIGNAL tb_rst   : STD_ULOGIC := '1';
    SIGNAL tb_clk   : STD_ULOGIC := '0';
    
    signal tb_message   :   STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0');
    signal tb_key       :   STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0');
    signal tb_modulus   :   STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0');

    signal tb_valid_in      : STD_ULOGIC := '0';
    signal tb_ready_in      : STD_ULOGIC;
    signal tb_ready_out     : STD_ULOGIC := '1';
    signal tb_valid_out     : STD_ULOGIC;
    signal tb_result        : STD_ULOGIC_VECTOR(input_width-1 downto 0) := (others => '0') ;

    signal tb_last_in       : STD_ULOGIC := '0';
    signal tb_last_out      : STD_ULOGIC;
    file input_file : TEXT open READ_MODE is "core_cluster_2_tb.txt";

begin

    PROC_CLK : process is
    begin
        WAIT FOR CLOCK_PERIOD/2;
        tb_clk <= NOT tb_clk;
    end process;

    UUT : entity work.core_cluster 
        port map (
            valid_in	=> tb_valid_in,
            ready_in	=> tb_ready_in,

            --input data
            message 	=> tb_message,
            key 		=> tb_key,
            modulus     => tb_modulus,
            
            --ouput controll
            ready_out	=> tb_ready_out,
            valid_out	=> tb_valid_out,

            --output data
            result 		=> tb_result, 

            clk => tb_clk,
            reset_n => tb_rst,
            last_msg_in => tb_last_in,
            last_msg_out => tb_last_out

        );

    RESET_PROC : process is
    begin
        wait for RESET_TIME;
        tb_rst <= '0';
        wait for 2*CLOCK_PERIOD;
        tb_rst <= '1';
        wait;
    end process;

    TEST_ROUTINE_OUTPUT_CHECK : process is
        variable i_output: INTEGER := 0;
        variable last : BOOLEAN := TRUE;
    begin
        while(last) loop
            WAIT UNTIL rising_edge(tb_clk);
            if(tb_valid_out = '1') then 
                assert tb_result = tb_result_check_fifo(i_output)
                    report "FAILED AT ITERATION " & integer'image(i_output) &  " UUT result: " & integer'image(to_integer(unsigned(tb_result))) 
                    & "\n CORRECT result: " & integer'image(to_integer(unsigned(tb_result_check_fifo(i_output))))
                    severity failure;
                report "CORRECT ITERATION " & integer'image(i_output);
                i_output := i_output +1;
            end if;
            if(tb_last_out = '1' )then
                last := FALSE; 
            end if;
        end loop;          
        WAIT UNTIL rising_edge(tb_clk);
        assert false report "TEST SUCCESSFULL" severity failure;
    end process;
    TEST_ROUTINE : process is
        variable line_buffer : line;
        variable line_blank  : line;
        variable read_value : STD_LOGIC_VECTOR(input_width-1 downto 0) := (others => '0') ;
        variable i_input : INTEGER := 0;
        variable good_read : BOOLEAN := TRUE;
        
    begin

        readline(input_file, line_buffer);             -- Read key line
        report "Line read = " & line_buffer.all severity NOTE;
        hread(line_buffer, read_value, good_read);
        assert good_read report "Error: key not read" severity FAILURE;
        tb_key <= read_value;

        readline(input_file, line_buffer);             -- Read modulus line
        report "Line read = " & line_buffer.all severity NOTE;
        hread(line_buffer, read_value, good_read);        
        assert good_read report "Error: modulus not read" severity FAILURE;
        tb_modulus <= read_value;
        
        readline(input_file, line_blank);             -- Read blanck line
        WAIT UNTIL tb_rst = '1';
        
        while not endfile(input_file) loop
            WAIT UNTIL rising_edge(tb_clk);
            if(tb_valid_in = '1' and tb_ready_in = '0') then
                tb_message <= tb_message; 
                tb_valid_in <= '1';
            elsif(tb_ready_in = '1') then
                readline(input_file, line_buffer);             -- Read message line
                report "Line read = " & line_buffer.all severity NOTE;
                hread(line_buffer, read_value, good_read);
                assert good_read report "Error: message not read" severity FAILURE;
                tb_message <= read_value;

                readline(input_file, line_buffer);             -- Read result line
                report "Line read = " & line_buffer.all severity NOTE;
                hread(line_buffer, read_value, good_read);        
                assert good_read report "Error: result not read" severity FAILURE;
                tb_result_check_fifo(i_input) <= read_value;
                
                readline(input_file, line_blank);             -- Read blanck line
                
                tb_valid_in <= '1';
                if(endfile(input_file)) then
                    tb_last_in <= '1';
                end if;
                i_input := i_input +1;
            end if;
        end loop;
        wait;
    end process;
end architecture;