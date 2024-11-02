library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_utilities.all;
use work.pwr_message_type.all;


entity exponentiation is
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
		pwr_message : in pwr_message_array; --Need to be adapted in the rsa_msgin

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
end exponentiation;


architecture expBehave of exponentiation is
    -- States for the state machine
    type state is (IDLE, POWER, MULTIPLY, DONE);
    signal curr_state, next_state : state := IDLE;
    signal input_en             : std_ulogic;
	signal partial_res          : STD_ULOGIC_VECTOR(C_block_size-1 downto 0):= (others => '0');
	signal partial_pwr			: STD_ULOGIC_VECTOR(2*C_block_size-1 downto 0):= (others => '0');
	signal i 					: unsigned(6 downto 0) := (others => '0'); --Works only for 256 bits here
	signal f_i 					: STD_ULOGIC_VECTOR(2 downto 0);
	signal mult_en  			: std_ulogic;
    signal mult_a 				: STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
    signal mult_b 				: STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
    signal mult_out 			: STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
    signal mult_done			: std_ulogic;

    component modulus_multiplication is
        generic(
            C_block_size : integer := 256
        );
        port(
            clk                 : in STD_ULOGIC;
            reset_n             : in STD_ULOGIC;

            enable_i            : in STD_ULOGIC;
            input_a             : in STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
            input_b             : in STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
            modulus             : in STD_ULOGIC_VECTOR(C_block_size-1 downto 0);

            output              : out STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
            output_ready        : out STD_ULOGIC
        );
    end component modulus_multiplication;

    
begin

    mod_mult : component modulus_multiplication 
        port map(
                clk => clk, 
                reset_n => reset_n, 
                enable_i => mult_en,
                input_a => mult_a, 
                input_b => mult_b, 
                modulus => modulus,
                output => mult_out, 
                output_ready => mult_done
        );

input_en <= valid_in; ---Need to add a "is_active" variable. then valid_in and not(is_active)

CombProc : process(curr_state, input_en )
    variable padded_key : STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1+ 2 downto 0) := (others => '0'); 
    begin
        case curr_state is
            when IDLE =>
                partial_res <= (others => '0');
                partial_pwr <= (others => '0');
                f_i <= (others => '0');
                i <= to_unsigned(85,7);
                mult_en <= '0';
                mult_a <= (others => '0');
                mult_b <= (others => '0');
                padded_key := "00" & key;
                result <= (others => '0');
                valid_out <= '0'; 
                if (input_en = '1') then
                    if (key(255) = '1') then
                        partial_res <= message;
                    else
                        partial_res(0) <= '1';
                    end if;
                    next_state <= POWER;
                else
                    next_state <= IDLE;
                end if;


            when POWER =>
                if (i >= 0) then
                    for j in 1 to 3 loop
                        partial_pwr <= std_ulogic_vector(unsigned(partial_res) * unsigned(partial_res));
                        partial_res <= partial_pwr(255 downto 0);
                    end loop;
                    --partial_pwr <= STD_ULOGIC_VECTOR(unsigned(partial_res) ** 8);
                    f_i <= padded_key(3*TO_INTEGER(i)+2 downto 3*TO_INTEGER(i));
                    if f_i /= "000" then
                        mult_a <= partial_res;
                        mult_b <= pwr_message(TO_INTEGER(unsigned(f_i))-1);
                        mult_en <= '1';
                        next_state <= MULTIPLY;
                    else 
                        mult_a <= (others => '0') ;
                        mult_b <= (others => '0') ;
                        mult_en <= '0';
                        next_state <= curr_state;
                    end if;
                    i <= i - 1;    
                else
                    next_state <= DONE;
                end if;

            when MULTIPLY =>
                if (mult_done = '1') then
                    partial_res <= mult_out;
                    next_state <= POWER;
                else 
                    partial_res <= partial_res;
                    next_state <= curr_state;
                end if;

            when DONE =>
                valid_out <= '1';               
                result <= partial_res;  
                next_state <= IDLE;       

            when others =>
                next_state <= IDLE;
        end case;
    end process;

SynchProc   : process (reset_n, clk)
                begin
                    if (reset_n = '0') then
                        curr_state <= IDLE;
                    elsif rising_edge(clk) then
                        curr_state <= next_state;
                    end if;
                end process SynchProc;

	--result <= partial_res;
	--ready_in <= ready_out;
	--valid_out <= valid_in;

end expBehave;
