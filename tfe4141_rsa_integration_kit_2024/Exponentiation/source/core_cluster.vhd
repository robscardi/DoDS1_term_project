library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_utilities.all;
entity core_cluster is
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
end core_cluster;

architecture bhv of core_cluster is

    type FIFO is array(Cluster_Num-1 downto 0) of STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);

    signal fifo_input : FIFO;       -- stores the input messages
    signal fifo_in_ready    : STD_LOGIC_VECTOR(Cluster_Num-1 downto 0); -- <- exponentiation_inst(i).ready_out

    signal exp_result : FIFO;       -- stores the output results

    signal exp_valid_out    : STD_LOGIC_VECTOR(Cluster_Num-1 downto 0); -- <- exponentiation_inst(i).valid_out 
    signal exp_valid_in     : STD_LOGIC_VECTOR(Cluster_Num-1 downto 0); -- <- exponentiation_inst(i).valid_in
    signal exp_ready_in     : STD_LOGIC_VECTOR(Cluster_Num-1 downto 0); -- <- exponentiation_inst(i).ready_in
    signal exp_ready_out    : STD_LOGIC_VECTOR(Cluster_Num-1 downto 0); -- <- exponentiation_inst(i).ready_out
    
    signal counter_fifo_in          : unsigned(log2c(Cluster_Num)-1 downto 0) := (others => '0'); -- points to the current available core         
    signal counter_fifo_in_next     : unsigned(log2c(Cluster_Num)-1 downto 0) := (others => '0'); -- points to the next availabel core       
    
    signal counter_gen_out          : unsigned(log2c(Cluster_Num)-1 downto 0) := (others => '0'); -- points to the core with the current result

    signal is_last              : STD_LOGIC_VECTOR(Cluster_Num-1 downto 0) := (others => '0'); -- (i) is 1 if the i-th message is the last
    component exponentiation is
	generic (
		C_block_size : integer := C_block_size
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
		reset_n 	: in STD_ULOGIC
	);
    end component;
    
begin
    -- Instantiate the cores
    GENEREATE_CLUSTER : for i in Cluster_Num-1 downto 0 generate
        exponentiation_inst: exponentiation
         generic map(
            C_block_size => C_block_size
        )
         port map(
            valid_in => exp_valid_in(i),
            ready_in => exp_ready_in(i),
            message => fifo_input(i),
            key => key,
            ready_out => exp_ready_out(i),
            valid_out => exp_valid_out(i),
            result => exp_result(i),
            modulus => modulus,
            clk => clk,
            reset_n => reset_n
        );

    end generate;
    ----------------------------------------------------------------------------------------------
    -- Synchronous process that manages the fifo_input, the ready_in and the last_msg_in ports. --
    -- This process assign a message sequentially to each core whenever the core is available.  --
    -- counter_fifo_in points to the current core, while counter_fifo_in_next to the successive,--
    -- in order to obtain the rigth signal for the ready_in signal.                             --
    ----------------------------------------------------------------------------------------------
    FILL_FIFO_IN_PROC : process (clk, reset_n)
    begin
        if(reset_n = '0') then
            fifo_input <= (others => (others => '0'));  
            ready_in <= '1';
            is_last <= (others => '0');
            exp_valid_in <= (others => '0');
            fifo_in_ready <= (others => '1');
            counter_fifo_in <= (others => '0');
            counter_fifo_in_next <= TO_UNSIGNED(1, counter_fifo_in_next'length);
        elsif(rising_edge(clk)) then 
            exp_valid_in <= (others => '0');
            if(exp_ready_in(to_integer(counter_fifo_in_next)) = '1') then
                fifo_in_ready(to_integer(counter_fifo_in_next)) <= '1';
            else
                fifo_in_ready(to_integer(counter_fifo_in_next)) <= fifo_in_ready(to_integer(counter_fifo_in_next));
            end if;
            if(valid_in = '1' and (ready_in = '1' )) then
                fifo_in_ready(to_integer(counter_fifo_in)) <= '0';
                fifo_input(to_integer(counter_fifo_in)) <= message;
                exp_valid_in(to_integer(counter_fifo_in)) <= '1';
                is_last(to_integer(counter_fifo_in)) <= last_msg_in;
                counter_fifo_in <= counter_fifo_in_next;
                if(to_integer(counter_fifo_in_next) = Cluster_Num-1 ) then
                    counter_fifo_in_next <= (others => '0');
                else
                    counter_fifo_in_next <= counter_fifo_in_next +1;
                end if;
            else 
                counter_fifo_in <= counter_fifo_in;
                counter_fifo_in_next <= counter_fifo_in_next;
            end if;
            ready_in <= fifo_in_ready(to_integer(counter_fifo_in_next));
        end if;
    end process;

    ------------------------------------------------------------------------------------------------
    -- Synchronous process that manages the exp_result, the valid_out and the last_msg_out ports. --
    -- This process manages the results sequentially from each core whenever the core result is   --
    -- valid.                                                                                     --
    -- counter_gen_out points to the current core, while counter_fifo_in_next to the successive,  --
    -- in order to obtain the rigth signal for the ready_in signal.                               --
    ------------------------------------------------------------------------------------------------
    OUTPUT : process (clk, reset_n)
    begin
        if(reset_n = '0') then
            result <= (others => '0');
            last_msg_out <= '0';
            valid_out <= '0';
            counter_gen_out <= (others => '0');
            exp_ready_out <= (others => '0');
        elsif(rising_edge(clk)) then 
            valid_out <= '0';
            exp_ready_out <= (others => '0');            
            result <= exp_result(to_integer(counter_gen_out));
            last_msg_out <= '0';
            if(ready_out = '1') then
                if(exp_valid_out(to_integer(counter_gen_out)) = '1') then
                    last_msg_out <= is_last(to_integer(counter_gen_out));
                    valid_out <= '1';
                    exp_ready_out(to_integer(counter_gen_out)) <= '1'; 
                    if(to_integer(counter_gen_out) = Cluster_Num-1 ) then
                        counter_gen_out <= (others => '0'); 
                    else 
                        counter_gen_out <= counter_gen_out +1; 
                    end if;
                else 
                    counter_gen_out <= counter_gen_out;
                end if;
            else
                if(valid_out = '1') then 
                    valid_out <= '1';
                else
                    valid_out <= '0';
                end if;
            end if;
        end if;
    end process;
end architecture;




