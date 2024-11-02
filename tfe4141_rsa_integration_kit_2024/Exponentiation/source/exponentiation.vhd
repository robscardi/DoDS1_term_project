library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_utilities.all;
use work.pwr_message_type.all;
use work.fsm.all;

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
		--pwr_message : in pwr_message_array; --Need to be adapted in the rsa_msgin

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
		
		f_i_out : out std_ulogic_vector(2 downto 0);
		i_out : out integer;
		curr_state_out : out state;
		next_state_out : out state;
		mult_done_out : out std_ulogic;
		mult_en_out : out std_ulogic;
		mult_a_out : out std_ulogic_vector(255 downto 0);
	    mult_b_out : out std_ulogic_vector(255 downto 0);
	    partial_pwr_out : out std_ulogic_vector(255 downto 0);
	    partial_res_out : out std_ulogic_vector(255 downto 0)

		
	);
end exponentiation;


architecture expBehave of exponentiation is
    -- States for the state machine
    --type state is (IDLE, SQUARE1, SQUARE2, SQUARE3, MULTIPLY, DONE);
    signal curr_state, next_state : state;
    signal input_en             : STD_ULOGIC;
    signal is_active            : STD_ULOGIC;
	signal partial_res          : STD_ULOGIC_VECTOR(C_block_size-1 downto 0):= (others => '0');
	signal partial_pwr			: STD_ULOGIC_VECTOR(C_block_size-1 downto 0):= (others => '0');
	signal i 					: unsigned(6 downto 0); --Works only for 256 bits here
	signal nxt_i 				: unsigned(6 downto 0); --Works only for 256 bits here
	signal f_i 					: STD_ULOGIC_VECTOR(2 downto 0);
	signal mult_en  			: STD_ULOGIC;
    signal mult_a 				: STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
    signal mult_b 				: STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
    signal mult_out 			: STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
    signal mult_done			: STD_ULOGIC;
    signal pwr_message          : pwr_message_array;
    signal inter                : STD_ULOGIC_VECTOR(C_block_size-1 downto 0);



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

    mod_mult : modulus_multiplication 
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

input_en <= valid_in and not(is_active);
ready_in <= not(is_active);

-- Signals to observe during testbench
f_i_out <= f_i;
i_out <= TO_INTEGER(i);
curr_state_out <= curr_state;
next_state_out <= next_state;
mult_done_out <= mult_done;
mult_en_out <= mult_en;
mult_a_out <= mult_a;
mult_b_out <= mult_b;
partial_pwr_out <= partial_pwr;
partial_res_out <= partial_res;
--



CombProc : process(curr_state, input_en, key, message,i,nxt_i, partial_res, partial_pwr, f_i, pwr_message, mult_en, mult_done,mult_out, ready_out)
--CombProc : process(curr_state, input_en)
    begin
        case curr_state is
            when IDLE =>
                result <= (others => '0');
                valid_out <= '0';
                is_active <= '0';
                partial_res <= (others => '0');
                partial_pwr <= (others => '0');
                pwr_message <= (others => (others => '0'));
                inter <= (others => '0');
                f_i <= (others => '0');
                i <= to_unsigned(84,7);
                nxt_i <= to_unsigned(84,7);
                --mult_en <= '0';
                mult_a <= (others => '0');
                mult_b <= (others => '0');
                if (input_en = '1') then
                    if (key(255) = '1') then
                        partial_res <= message;
                    else
                        partial_res(0) <= '1';
                    end if;
                    next_state <= PRECALC1;
                else
                    next_state <= IDLE;
                end if;
                
            when PRECALC1 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a(0) <= '1';
                mult_b <= message;
                if (mult_done = '1' and mult_en = '0') then
                    inter <= mult_out;
                    pwr_message(0) <= inter;
                    next_state <= PRECALC2;
                end if;
                
            when PRECALC2 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                
                mult_a <= pwr_message(0);
                mult_b <= pwr_message(0);
                if (mult_done = '1' and mult_en = '0') then
                    pwr_message(1) <= mult_out;
                    next_state <= PRECALC3;
                end if;
                
            when PRECALC3 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= pwr_message(1);
                if (mult_done = '1' and mult_en = '0') then
                    pwr_message(2) <= mult_out;
                    next_state <= PRECALC4;
                end if;
                
            when PRECALC4 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= pwr_message(2);
                if (mult_done = '1' and mult_en = '0') then
                    pwr_message(3) <= mult_out;
                    next_state <= PRECALC5;
                end if;
                 
             when PRECALC5 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= pwr_message(3);
                if (mult_done = '1' and mult_en = '0') then
                    pwr_message(4) <= mult_out;
                    next_state <= PRECALC6;
                end if;
                
            when PRECALC6 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= pwr_message(4);
                if (mult_done = '1' and mult_en = '0') then
                    pwr_message(5) <= mult_out;
                    next_state <= PRECALC7;
                end if;
                
            when PRECALC7 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= pwr_message(5);
                if (mult_done = '1' and mult_en = '0') then
                    pwr_message(6) <= mult_out;
                    next_state <= SQUARE1;
                end if;                 
            
            when SQUARE1 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0'; -- JUST TO TEST PRECALC
                i <= nxt_i;
                if (TO_INTEGER(i) < 100) then
                    f_i <= key((3*TO_INTEGER(i)+2) downto (3*TO_INTEGER(i)));
                    mult_a <= partial_res;
                    mult_b <= partial_res;
                    if (mult_done = '1' and mult_en = '0') then
                        next_state <= SQUARE2;
                        partial_pwr <= mult_out;
                    end if;  
                else
                    next_state <= DONE;
                    --result <= partial_res;
                end if;                
                
            when SQUARE2 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= partial_pwr;
                mult_b <= partial_pwr;
                if (mult_done = '1' and mult_en = '0') then
                    next_state <= SQUARE3;
                    partial_res <= mult_out;
                    nxt_i <= i-1;
                end if;
                
            when SQUARE3 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= partial_res;
                mult_b <= partial_res;
                if (mult_done = '1' and mult_en = '0') then
                    partial_pwr <= mult_out;
                    nxt_i <= i-1;
                    if (f_i /= "000") then
                        next_state <= MULTIPLY;
                    else
                        next_state <= SQUARE1;
                end if;
                end if;
                
                
            when MULTIPLY =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= partial_pwr;
                mult_b <= pwr_message(TO_INTEGER(unsigned(f_i))-1);
                if (mult_done = '1' and mult_en = '0') then
                    next_state <= SQUARE1;
                    partial_res <= mult_out;  
                end if;

            when DONE =>
                is_active <= '1';
                if (ready_out = '1') then
                    valid_out <= '1';               
                    result <= partial_res;  
                    next_state <= IDLE;
--                else
--                    result <= (others => '0');
--                    valid_out <= '0';
--                    next_state <= DONE;
                end if;       
    
            when others =>
                is_active <= '0';
                result <= (others => '0');
                valid_out <= '0';
                next_state <= IDLE;
        end case;
    end process;

SynchProc   : process (reset_n, clk)
                begin
                    if (reset_n = '0') then
                        curr_state <= IDLE;
                    elsif rising_edge(clk) then
                        curr_state <= next_state;
                        if (next_state /= curr_state) then
                            mult_en <= '1';
                        else
                            mult_en <= '0';
                        end if;
                    end if;
                end process SynchProc;

end expBehave;