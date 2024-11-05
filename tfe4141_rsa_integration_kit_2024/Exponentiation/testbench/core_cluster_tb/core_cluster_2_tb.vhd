LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;
use work.data_type.all;

ENTITY core_cluster_2_tb IS
END core_cluster_2_tb;

ARCHITECTURE bhvtb OF core_cluster_2_tb IS
    
    CONSTANT CLOCK_PERIOD : TIME := 10 ns;
    CONSTANT input_width : POSITIVE := 256;
    CONSTANT RESET_TIME     : TIME := 2*CLOCK_PERIOD;
    CONSTANT CLUSTER_NUM    : POSITIVE := 4;

    type num_array is array (natural range<>) of integer;
    subtype DATA is STD_ULOGIC_VECTOR(input_width-1 downto 0);
    

    SIGNAL tb_rst   : STD_ULOGIC := '1';
    SIGNAL tb_clk   : STD_ULOGIC := '0';
    
    signal tb_message  : DATA := (others => '0');
    signal tb_key  : DATA := (others => '0');
    signal tb_modulus  : DATA := (others => '0');

    signal tb_mod_res  : DATA := (others => '0');

    signal tb_enable_i      : STD_ULOGIC := '0';
    signal tb_output_valid  : STD_ULOGIC := '0';
    signal tb_valid_in      : STD_ULOGIC := '0';
    signal tb_ready_in      : STD_ULOGIC := '0';
    signal tb_ready_out     : STD_ULOGIC := '0';
    signal tb_valid_out     : STD_ULOGIC := '0';
    signal tb_result        : DATA       := (others => '0') ;

    signal tb_last_in       : STD_ULOGIC := '0';
    signal tb_last_out      : STD_ULOGIC := '0';


    component core_cluster is
	generic (
		C_block_size    : integer := 256;
        Cluster_Num     : positive := 10 
	);
	port (
		--input controll
		valid_in	: in STD_ULOGIC;
		ready_in	: out STD_ULOGIC;

		--input data
		message 	: in STD_ULOGIC_VECTOR ( C_block_size-1 downto 0 );
		key 		: in STD_ULOGIC_VECTOR ( C_block_size-1 downto 0 );

		--ouput controll
		ready_out	: in STD_ULOGIC;
		valid_out	: out STD_ULOGIC;

		--output data
		result 		: out STD_ULOGIC_VECTOR(C_block_size-1 downto 0);

		--modulus
		modulus 	: in STD_ULOGIC_VECTOR(C_block_size-1 downto 0);

		--utility
		clk 		: in STD_ULOGIC;
		reset_n 	: in STD_ULOGIC;

        last_msg_in    : in STD_ULOGIC;
        last_msg_out   : out STD_ULOGIC

	);
    end component;

    --alias tb_full_fifo_input is << signal core_cluster.full_fifo_input : STD_LOGIC >>;
    --alias tb_full_fifo_output is << signal core_cluster.full_fifo_output : STD_LOGIC >>;

begin

    PROC_CLK : process is
    begin
        WAIT FOR CLOCK_PERIOD/2;
        tb_clk <= NOT tb_clk;
    end process;

    UUT : core_cluster 
        generic map (
            C_block_size => input_width,
            Cluster_num => CLUSTER_NUM
        )
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

    TEST_ROUTINE : process is
        variable correct_res : unsigned(input_width-1 downto 0) := TO_UNSIGNED(0, input_width);
        variable line_buffer : line;
        variable read_value : STD_LOGIC_VECTOR(input_width-1 downto 0) := (others => '0') ;
        variable file_status : FILE_OPEN_STATUS;
        variable i : INTEGER := 0;
        variable good_read : BOOLEAN := TRUE;
        
        file input_file : TEXT;
    begin
        file_open(file_status, input_file, "core_cluster_2_tb.txt", read_mode);
        if file_status = open_ok then
            report "File opened successfully.";
        elsif file_status = status_error then
            report "File open failed due to a status error.";
        elsif file_status = name_error then
            report "File open failed due to a name error.";
        else
            report "Unknown file open status.";
        end if;

        readline(input_file, line_buffer);             -- Read each line
        report "Line read = " & line_buffer.all severity NOTE;
        hread(line_buffer, read_value, good_read);
        if not good_read then
            report "Error: key not read";
        end if;        
        tb_key <= read_value;
        readline(input_file, line_buffer);             -- Read each line
        hread(line_buffer, read_value);        
        tb_modulus <= read_value;
        
        WAIT UNTIL tb_rst = '1';
        
        while not endfile(input_file) loop
            WAIT UNTIL rising_edge(tb_clk);
            tb_enable_i <= '1';
            WAIT UNTIL rising_edge(tb_clk);
            tb_enable_i <= '0';
            WAIT UNTIL tb_output_valid = '1';
            assert tb_mod_res = STD_ULOGIC_VECTOR(correct_res)
                report "FAILED AT ITERATION " & integer'image(i) &  " UUT result: " & integer'image(to_integer(unsigned(tb_mod_res))) & "\n CORRECT result: " & integer'image(to_integer(correct_res))
                severity failure;
            i := i +1;
        end loop;
        WAIT UNTIL rising_edge(tb_clk);
        assert false report "TEST SUCCESSFULL" severity failure;
    end process;

end architecture;