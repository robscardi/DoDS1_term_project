LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;
use work.data_type.all;

ENTITY core_cluster_1_tb IS
END core_cluster_1_tb;

ARCHITECTURE projecttb OF core_cluster_1_tb IS
    
    CONSTANT CLOCK_PERIOD : TIME := 10 ns;
    CONSTANT input_width : POSITIVE := 256;
    CONSTANT RESET_TIME     : TIME := 2*CLOCK_PERIOD;
    CONSTANT CLUSTER_NUM    : POSITIVE := 4;

    type num_array is array (natural range<>) of integer;
    subtype DATA is STD_ULOGIC_VECTOR(input_width-1 downto 0);
    

    SIGNAL tb_rst   : STD_ULOGIC := '1';
    SIGNAL tb_clk   : STD_ULOGIC := '1';
    
    signal tb_message  : DATA := (others => '0');
    signal tb_key  : DATA := (others => '0');
    signal tb_modulus  : DATA := (others => '0');

    signal tb_valid_in      : STD_ULOGIC := '0';
    signal tb_ready_in      : STD_ULOGIC := '0';
    signal tb_ready_out     : STD_ULOGIC := '0';
    signal tb_valid_out     : STD_ULOGIC := '0';
    signal tb_result        : DATA       := (others => '0') ;

    signal tb_last_in       : STD_ULOGIC := '0';
    signal tb_last_out      : STD_ULOGIC := '0';

    -- SCENARIO SIGNALS
    signal input_message    : num_array(Cluster_Num-1 downto 0) := ( 0 => 3649, 1 => 2345, 2 => 2123, 3 => 9089 );
    signal input_key        : INTEGER                           := ( 1230   );
    signal input_mod        : INTEGER                           := ( 302304 );


    component core_cluster is
	generic (
		C_block_size    : integer := 256;
        Cluster_Num     : positive := CLUSTER_NUM
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
        variable counter : integer := 0;
        variable i : integer := 0;
    begin
        WAIT until tb_rst = '0';
        WAIT until tb_rst = '1';
        tb_modulus  <= STD_ULOGIC_VECTOR(to_unsigned(input_mod, tb_modulus'length));
        tb_key      <= STD_ULOGIC_VECTOR(to_unsigned(input_key, tb_key'length));
        tb_ready_out <= '1';
        while(i<input_message'length) loop
            if (tb_ready_in = '1') then
                tb_message <= STD_LOGIC_VECTOR(to_unsigned(input_message(i), input_width));
                tb_valid_in <= '1'; 
            end if;
            if (i = input_message'length-1) then
                tb_last_in <= '1';
            end if;
            i := i+1;
            WAIT until rising_edge(tb_clk);
        end loop;
        tb_valid_in <= '0';
        while(true) loop
            WAIT UNTIL rising_edge(tb_clk);
            if(tb_valid_out = '1') then
                counter := counter +1;
                report "output " & integer'image(counter) & " : " & integer'image(to_integer(unsigned(tb_result)));
            end if;
            if(tb_last_out = '1') then
                assert (counter = input_message'length)
                    report "FAILED: found " & integer'image(counter) & " output from " & integer'image(input_message'length) &" input"
                    severity failure;
                assert false report "TEST SUCCESSFULL" severity failure;
            end if;
        end loop;            
    end process;
end architecture;