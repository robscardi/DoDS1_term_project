library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_utilities.all;


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
    type state is (IDLE, PRECALC1, PRECALC2, PRECALC3, PRECALC4, PRECALC5, PRECALC6, PRECALC7, SQUARE1, SQUARE2, SQUARE3, MULTIPLY, DONE);
    type pwr_message_array is array (0 to 6) of STD_ULOGIC_VECTOR(255 downto 0);
    signal curr_state           : state := IDLE;
    signal next_state           : state := IDLE;
    signal pwr_message          : pwr_message_array;
    signal counter_precalc      : unsigned(2 downto 0);
    signal input_en             : STD_ULOGIC;
    signal is_active            : STD_ULOGIC := '0';
	signal partial_res          : STD_ULOGIC_VECTOR(C_block_size-1 downto 0):= (others => '0');
	signal i 					: unsigned(6 downto 0); --Works only for 256 bits here
	signal f_i 					: STD_ULOGIC_VECTOR(2 downto 0);
	signal mult_en  			: STD_ULOGIC;
    signal mult_a 				: STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
    signal mult_b 				: STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
    signal mult_out 			: STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
    signal mult_done			: STD_ULOGIC;


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



CombProc : process(curr_state, input_en, key, message,i, partial_res, f_i, mult_en, mult_done,mult_out, ready_out, pwr_message)
    begin
        next_state <= IDLE;
        case curr_state is
            when IDLE =>
                result <= (others => '0');
                valid_out <= '0';
                is_active <= '0';
                --pwr_message <= (others => (others => '0'));
                mult_a <= (others => '0');
                mult_b <= (others => '0');
                if (input_en = '1') then --START
                    next_state <= PRECALC1;

                end if;
                
            -- PRECALCULATION of (2**k)[modulus] for k from 1 to 7 (octal method requirement)   
            when PRECALC1 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';                    
                mult_a <= (others => '0');
                mult_a(0) <= '1';
                mult_b <= message;
                if (mult_done = '1' and mult_en = '0') then
                    --pwr_message(0) <= mult_out;
                    next_state <= PRECALC2;
                else
                    next_state <= PRECALC1;
                end if;
                
            when PRECALC2 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= partial_res;
                mult_b <= partial_res;
                if (mult_done = '1' and mult_en = '0') then
                   -- pwr_message(1) <= mult_out;
                    next_state <= PRECALC3;
                else
                    next_state <= PRECALC2;
                end if;
                
            when PRECALC3 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= partial_res;
                mult_b <= pwr_message(0);
                if (mult_done = '1' and mult_en = '0') then
                    --pwr_message(2) <= mult_out;
                    next_state <= PRECALC4;
                else
                    next_state <= PRECALC3;
                end if;
                
            when PRECALC4 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= partial_res;                
                mult_b <= pwr_message(0);
                if (mult_done = '1' and mult_en = '0') then
                   -- pwr_message(3) <= mult_out;
                    next_state <= PRECALC5;
                else
                    next_state <= PRECALC4;
                end if;
                 
             when PRECALC5 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= partial_res;                
                mult_b <= pwr_message(0);
                if (mult_done = '1' and mult_en = '0') then
                    --pwr_message(4) <= mult_out;
                    next_state <= PRECALC6;
                else
                    next_state <= PRECALC5;
                end if;
                
            when PRECALC6 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= partial_res;                
                mult_b <= pwr_message(0);
                if (mult_done = '1' and mult_en = '0') then
                   --pwr_message(5) <= mult_out;
                    next_state <= PRECALC7;
                else
                    next_state <= PRECALC6;
                end if;
                
            when PRECALC7 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= partial_res;
                mult_b <= pwr_message(0);
                if (mult_done = '1' and mult_en = '0') then
                    --pwr_message(6) <= mult_out;
                    next_state <= SQUARE1;
                else
                    next_state <= PRECALC7;
                end if;                 
            
            --For each block of 3 bits (f_i), elevate the partial result to power 8 (square 3 times)
            when SQUARE1 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0'; 
                if (TO_INTEGER(i) < 100) then
                    mult_a <= partial_res;
                    mult_b <= partial_res;
                    if (mult_done = '1' and mult_en = '0') then
                        next_state <= SQUARE2;
                    else
                        next_state <= SQUARE1;
                    end if;  
                else
                    mult_a <= (others => '0');
                    mult_b <= (others => '0');
                    next_state <= DONE;
                end if;                
                
            when SQUARE2 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= partial_res;
                mult_b <= partial_res;
                if (mult_done = '1' and mult_en = '0') then
                    next_state <= SQUARE3;
                else
                    next_state <= SQUARE2;
                end if;
                
            when SQUARE3 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= partial_res;
                mult_b <= partial_res;
                if (mult_done = '1' and mult_en = '0') then
                    if (f_i /= "000") then
                        next_state <= MULTIPLY;
                    else
                        next_state <= SQUARE1;
                    end if;
                else
                    next_state <= SQUARE3;
                end if;
                
            -- Additional modular multiplication when f_i /= "000"
            when MULTIPLY =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= partial_res;
                mult_b <= pwr_message(TO_INTEGER(unsigned(f_i))-1);
                if (mult_done = '1' and mult_en = '0') then
                    next_state <= SQUARE1;
                else
                    next_state <= MULTIPLY; 
                end if;

            when DONE =>
                is_active <= '1';
                mult_a <= (others => '0');
                mult_b <= (others => '0');
                if (ready_out = '1') then
                    valid_out <= '1';
                    result <= partial_res;                 
                    next_state <= IDLE;
                else
                    valid_out <= '0';
                    result <= (others => '0');
                    next_state <= DONE;
                end if;       
    
            when others =>
                is_active <= '0';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= (others => '0');
                mult_b <= (others => '0');
                next_state <= IDLE;
        end case;
    end process;

SynchProc   : process (reset_n, clk,next_state,curr_state)
                begin
                    if (reset_n = '0') then
                        curr_state <= IDLE;
                        mult_en <= '0';
                    elsif rising_edge(clk) then
                        curr_state <= next_state;
                        -- Enable modular multiplication when switching states
                        if (next_state /= curr_state) then
                            mult_en <= '1';
                        else
                            mult_en <= '0';
                        end if;
                    end if;
                end process SynchProc;
                
                
i_Proc :    process(reset_n, clk, next_state,curr_state)
                begin 
                    if (reset_n = '0' or curr_state = IDLE) then
                        i <= to_unsigned(85,7);
                    elsif (rising_edge(clk) and next_state = SQUARE1 and curr_state /= SQUARE1) then
                        i <= i - 1;
                    end if;
                end process i_Proc;
                
                
f_i_Proc :  process(reset_n, clk, curr_state,i)
                begin 
                    if (reset_n = '0' or curr_state = IDLE) then
                        f_i <= (others => '0');
                    elsif (rising_edge(clk) and curr_state = SQUARE1 and TO_INTEGER(i) < 85) then
                        f_i <= key((3*TO_INTEGER(i)+2) downto (3*TO_INTEGER(i)));
                    end if;
                end process f_i_Proc;
                
partial_res_Proc :  process(reset_n, clk,curr_state,next_state,key)
                begin 
                    if (reset_n = '0' or curr_state = IDLE) then
                        partial_res <= (others => '0');
                    elsif rising_edge(clk) then
                        if (curr_state = PRECALC7) then
                            -- OCTAL METHOD INITIALIZATION
                            if (key(255) = '1') then
                                partial_res <= message;
                            else
                                partial_res <= (others => '0');
                                partial_res(0) <= '1';
                            end if;
                        elsif (next_state /= curr_state and next_state /= DONE) then
                            partial_res <= mult_out;
                        end  if;
                    end if;
                end process partial_res_Proc;
                
pwr_message_Proc : process(reset_n, clk,curr_state,next_state,counter_precalc)
                    begin
                        if (reset_n = '0' or curr_state = IDLE) then
                            pwr_message <= (others => (others => '0'));
                            counter_precalc <= (others => '0');
                        elsif rising_edge(clk) then
                            if (next_state /= curr_state and curr_state /= IDLE and counter_precalc < 7) then
                                pwr_message(TO_INTEGER(counter_precalc)) <= mult_out;
                                counter_precalc <= counter_precalc + 1;
                            end if;                            
                        end if;
                    end process pwr_message_Proc;

end expBehave;
