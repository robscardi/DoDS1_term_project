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

    subtype DATA is STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
    type FIFO is array(Cluster_Num-1 downto 0) of STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);

    signal fifo_input : FIFO;       -- stores the input messages
    signal fifo_out   : FIFO;       -- stores the results
    
    signal exp_result : FIFO;

    signal exp_valid_out    : STD_LOGIC_VECTOR(Cluster_Num-1 downto 0); -- <- exponentiation_inst(i).valid_out 
    signal exp_valid_in     : STD_LOGIC_VECTOR(Cluster_Num-1 downto 0); -- <- exponentiation_inst(i).valid_in
    signal exp_ready_in     : STD_LOGIC_VECTOR(Cluster_Num-1 downto 0); -- <- exponentiation_inst(i).ready_in
    signal fifo_out_ready   : STD_LOGIC_VECTOR(Cluster_Num-1 downto 0); -- <- exponentiation_inst(i).ready_out

    signal full_fifo_input      : STD_LOGIC;     -- 1 if #Cluster_Num messages have arrived or last_msg_in = 1
    signal full_fifo_out        : STD_LOGIC;     -- 1 if #Cluster_Num messages have been processed
    signal output_completed     : STD_LOGIC;     
    signal counter_fifo_in : unsigned(log2c(Cluster_Num)-1 downto 0) := (others => '0');        
    signal counter_gen_out : unsigned(log2c(Cluster_Num)-1 downto 0) := (others => '0');

    signal is_last              : STD_LOGIC_VECTOR(Cluster_Num-1 downto 0); -- (i) is 1 if the i-th message is the last
    
    signal exp_valid_out_stable : STD_LOGIC_VECTOR(Cluster_Num-1 downto 0) := (others => '0'); -- counter for FILL_FIFO_IN process

    signal fin_reset            : STD_ULOGIC;
    component exponentiation is
	generic (
		C_block_size : integer := 256
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
            ready_out => fifo_out_ready(i),
            valid_out => exp_valid_out(i),
            result => exp_result(i),
            modulus => modulus,
            clk => clk,
            reset_n => reset_n
        );

    end generate;

    
    FILL_FIFO_IN_PROC : process (clk, reset_n, fin_reset)
    begin
        if(reset_n = '0' or fin_reset = '1') then
            counter_fifo_in <= (others => '0');
            fifo_input <= (others => (others => '0'));  
            full_fifo_input <= '0';
            ready_in <= '1';
            is_last <= (others => '0');
            exp_valid_in <= (others => '0'); 
        elsif(rising_edge(clk)) then 
            if(full_fifo_input = '1') then
                exp_valid_in <= (others => '0'); 
            end if;
            if(valid_in = '1' and full_fifo_input = '0') then
                fifo_input(to_integer(counter_fifo_in)) <= message;
                exp_valid_in(to_integer(counter_fifo_in)) <= '1';
                if (last_msg_in = '1') then
                    is_last(to_integer(counter_fifo_in)) <= '1';
                    full_fifo_input <= '1';
                end if;
                counter_fifo_in <= counter_fifo_in +1;
            end if;
            if (counter_fifo_in = TO_UNSIGNED(Cluster_Num-1, counter_fifo_in'length)) then
                full_fifo_input <= '1';
                ready_in <= '0';
            end if;
            if (output_completed = '1') then
                counter_fifo_in <= (others => '0');
                fifo_input <= (others => (others => '0'));
                full_fifo_input <= '0';
                is_last <= (others => '0'); 
            end if;  
        end if;

    end process;

    GENERATE_FIFO_OUT_READY : for i in Cluster_Num-1 downto 0 generate
        process (clk, reset_n, fin_reset)
        begin
            if reset_n = '0' or fin_reset = '1' then
                exp_valid_out_stable(i) <= '0'; 
                fifo_out_ready(i) <= '1' ;
                fifo_out(i) <= (others => '0') ; 
            elsif rising_edge(clk) then
                if(output_completed = '0') then
                    if(exp_valid_out(i) = '1') then
                        exp_valid_out_stable(i) <= '1';
                        fifo_out(i) <= exp_result(i);
                        fifo_out_ready(i) <= '0';
                    end if;
                else
                    exp_valid_out_stable(i) <= '0'; 
                    fifo_out_ready(i) <= '1'; 
                end if;
            end if;
        end process;
    end generate;

    FULL_FIFO_OUT_PROC : process (clk, reset_n, fin_reset)
    begin
        if(reset_n = '0' or fin_reset = '1') then
            full_fifo_out <= '0';
        elsif rising_edge(clk) then
            full_fifo_out <= and exp_valid_out_stable;
        end if;
    end process;

    OUTPUT : process (clk, reset_n, fin_reset)
    begin
        if(reset_n = '0' or fin_reset = '1') then
            counter_gen_out <= (others => '0');
            output_completed <= '0';
            result <= (others => '0');
            last_msg_out <= '0';
            valid_out <= '0';
            fin_reset <= '0';
        elsif(rising_edge(clk)) then 
            last_msg_out <= '0';
            valid_out <= '0';
            if(full_fifo_out = '1') then
                result <= fifo_out(to_integer(counter_gen_out));
                last_msg_out <= is_last(to_integer(counter_gen_out));
                valid_out <= '1';
                if(to_integer(counter_gen_out) = Cluster_Num-1 or is_last(to_integer(counter_gen_out)) = '1') then
                    output_completed <= '1';
                end if;
                if(ready_out = '1') then
                    counter_gen_out <= counter_gen_out +1;
                else 
                    counter_gen_out <= counter_gen_out;
                end if;
            end if;
            if(output_completed = '1') then
                fin_reset <= '1';
            end if;
        end if;
    end process;
end architecture;




