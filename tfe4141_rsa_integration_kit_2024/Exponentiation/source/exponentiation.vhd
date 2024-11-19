library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_utilities.all;

-- Modular exponentiation using the Octal Method algorithm
-- Works for 256 bits long inputs (would need some modifications to adapt it to any length)
entity exponentiation is
	generic (
		C_block_size : integer := 256
	);
	port (
		--input control
		valid_in	: in STD_ULOGIC;
		ready_in	: out STD_ULOGIC;

		--input data
		message 	: in STD_ULOGIC_VECTOR ( C_block_size-1 downto 0 );
		key 		: in STD_ULOGIC_VECTOR ( C_block_size-1 downto 0 );

		--ouput control
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
    type state is (IDLE, PRECALC2, PRECALC3, PRECALC4, PRECALC5, PRECALC6, PRECALC7, SQUARE1, SQUARE2, SQUARE3, MULTIPLY, DONE);
    -- Array type to store 7 values during precalculation
    type pwr_message_array is array (0 to 6) of STD_ULOGIC_VECTOR(255 downto 0);
    signal curr_state           : state := IDLE;
    signal next_state           : state := IDLE;
    signal pwr_message          : pwr_message_array;
    signal counter_precalc      : unsigned(2 downto 0);
    constant max_pre_counter    : unsigned(counter_precalc'range) := TO_UNSIGNED(6, counter_precalc'length);
    signal input_en             : STD_ULOGIC;
    signal is_active            : STD_ULOGIC := '0';
	signal partial_res          : STD_ULOGIC_VECTOR(C_block_size-1 downto 0):= (others => '0');
	signal i_counter 			: signed(7 downto 0);         --Works only for 256 bits here
    constant max_i_counter      : signed(i_counter'range) := TO_SIGNED(85, i_counter'length);
	signal key_block 			: STD_ULOGIC_VECTOR(2 downto 0);
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
        
input_en <= valid_in and not(is_active); --Start signal
ready_in <= not(is_active);


--Main process
CombProc : process(curr_state, input_en, key, message,i_counter, partial_res, key_block, mult_en, mult_done,mult_out, ready_out, pwr_message)
    begin
        next_state <= IDLE;
        case curr_state is
            when IDLE =>
                result <= (others => '0');
                valid_out <= '0';
                is_active <= '0';
                mult_a <= (others => '0');
                mult_b <= (others => '0');
                if (input_en = '1') then --START
                    next_state <= PRECALC2;
                else
                    next_state <= IDLE;
                end if;
                
            -- PRECALCULATION of (message**k)[modulus] for k from 1 to 7 (octal method requirement) 
                
            when PRECALC2 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= pwr_message(0);
                mult_b <= pwr_message(0);
                if (mult_done = '1' and mult_en = '0') then
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
                    next_state <= SQUARE1;
                else
                    next_state <= PRECALC7;
                end if;                 
            
            --Precalculation is done
            --For each block of 3 bits (f_i) in the key, elevate the partial result to power 8 (square 3 times)
            when SQUARE1 =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0'; 
                if (TO_INTEGER(i_counter) >= 0) then 
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
                    if (key_block /= "000") then
                        next_state <= MULTIPLY;
                    else
                        next_state <= SQUARE1;
                    end if;
                else
                    next_state <= SQUARE3;
                end if;
                
            -- Additional modular multiplication when key_block /= "000"
            when MULTIPLY =>
                is_active <= '1';
                result <= (others => '0');
                valid_out <= '0';
                mult_a <= partial_res;
                mult_b <= pwr_message(TO_INTEGER(unsigned(key_block))-1);
                if (mult_done = '1' and mult_en = '0') then
                    next_state <= SQUARE1;
                else
                    next_state <= MULTIPLY; 
                end if;

            when DONE =>
                is_active <= '1';
                mult_a <= (others => '0');
                mult_b <= (others => '0');
                result <= partial_res;
                valid_out <= '1';
                --Wait for the outside component to be ready to receive the output
                if (ready_out = '1') then
                    next_state <= IDLE;
                else
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

-- Updates the state at each positive clock edge
SynchProc   : process (reset_n, clk,next_state,curr_state)
                begin
                    if (reset_n = '0') then
                        curr_state <= IDLE;
                        mult_en <= '0';
                    elsif rising_edge(clk) then
                        curr_state <= next_state;
                        -- Enable modular multiplication for one clock cycle when switching states
                        if (next_state /= curr_state) then
                            mult_en <= '1';
                        else
                            mult_en <= '0';
                        end if;
                    end if;
                end process SynchProc;
                
-- Keeps track of the counter during the main loop (SQUARE1-2-3-MULTIPLY)             
i_Proc :    process(reset_n, clk)
                begin 
                    if (reset_n = '0') then
                        i_counter <= max_i_counter;
                    elsif (rising_edge(clk)) then
                        if(curr_state = IDLE) then
                            i_counter <= max_i_counter;
                        elsif(next_state = SQUARE1 and curr_state /= SQUARE1) then
                            i_counter <= i_counter - 1;
                        else 
                            i_counter <= i_counter;
                        end if;
                    end if;
                end process i_Proc;
                
-- Keeps track of the current key 3-bits-group during the main loop                           
KEY_BLOCK_Proc :  process(reset_n, clk)
                begin 
                    if (reset_n = '0') then
                        key_block <= (others => '0');
                    elsif (rising_edge(clk)) then
                        if(curr_state = IDLE) then
                            key_block <= (others => '0');
                        elsif( curr_state = SQUARE1 and TO_INTEGER(i_counter) >= 0) then
                            key_block <= key((3*TO_INTEGER(i_counter)+2) downto (3*TO_INTEGER(i_counter)));
                        end if;
                    end if;
                end process KEY_BLOCK_Proc;
       
--Stores the result of the last modular multiplication (which becomes the input of the next one)               
partial_res_Proc :  process(reset_n, clk)
                begin 
                    if (reset_n = '0') then
                        partial_res <= (others => '0');
                    elsif rising_edge(clk) then
                        if (curr_state = IDLE) then 
                            partial_res <= (others => '0');
                        elsif (curr_state = PRECALC7) then
                            -- OCTAL METHOD INITIALIZATION
                            if (key(255) = '1') then
                                partial_res <= message;
                            else
                                partial_res <= (others => '0');
                                partial_res(0) <= '1';
                            end if;
                        elsif (next_state /= curr_state and next_state /= DONE) then
                            partial_res <= mult_out;
                        else
                            partial_res <= partial_res;
                        end  if;
                    end if;
                end process partial_res_Proc;

--Fills the pwr_message array during the precalculation states                
pwr_message_Proc : process(reset_n, clk,curr_state,next_state,counter_precalc)
                    begin
                        if (reset_n = '0') then
                            pwr_message <= (others => (others => '0'));
                            counter_precalc <= (others => '0');
                        elsif rising_edge(clk) then
                            if(curr_state = IDLE ) then
                                pwr_message <= (others => (others => '0'));
                                counter_precalc <= (others => '0');
                                if(input_en = '1') then
                                    pwr_message(0) <= message;
                                else
                                    pwr_message(0) <= pwr_message(0);
                                end if;
                            elsif (next_state /= curr_state and curr_state /= IDLE and counter_precalc < max_pre_counter) then
                                pwr_message <= pwr_message;
                                pwr_message(TO_INTEGER(counter_precalc)+1) <= mult_out;
                                counter_precalc <= counter_precalc + 1;
                            else
                                counter_precalc <= counter_precalc;
                                pwr_message <= pwr_message;
                            end if;                            
                        end if;
                    end process pwr_message_Proc;

end expBehave;
