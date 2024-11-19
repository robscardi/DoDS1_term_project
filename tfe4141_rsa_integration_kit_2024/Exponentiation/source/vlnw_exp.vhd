library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_utilities.all;


--hp : message < modulus;


entity vlnw_exponentiation is
	generic (
		c_block_size    : integer := 256
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



end vlnw_exponentiation;

architecture bhv of vlnw_exponentiation is
    constant D             : integer := 4;
    constant MATRIX_LENGHT : POSITIVE := ((2**D)/2);
 

    type M_MATRIX_TYPE is array(MATRIX_LENGHT-1 downto 0) of STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
    subtype DATA is STD_ULOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
    
    signal M : DATA;
    signal K : DATA;
    signal N : DATA;
    
    signal pre_done : STD_LOGIC;
    signal exp_done : STD_LOGIC;
    
    type STATE is (IDLE, PRE, EXP, DONE);
    signal MM_STATE_curr : STATE;    
    signal MM_STATE_next : STATE;


    signal M_MATRIX : M_MATRIX_TYPE;
    type PRLM_STATE is (IDLE, WORKING, WAITING, DONE);
    signal PRLMM_STATE_curr : PRLM_STATE;
    signal PRLMM_STATE_next : PRLM_STATE;
    

    signal partial_res  : DATA;

    type EXP_STATE is (IDLE, SRCH_BGN, NW_WINDOW, WAITING_NW_MULT, NW_EXP, ZW, WAITING, DONE);
    signal EXPNM_STATE_curr : EXP_STATE;
    signal EXPNM_STATE_next : EXP_STATE;


    signal PRLM_input_a : DATA;
    signal PRLM_input_b : DATA;
    signal PRLM_en_mult : STD_LOGIC;

    signal EXP_input_a : DATA;
    signal EXP_input_b : DATA;
    signal EXP_en_mult  : STD_LOGIC;
    
    -- modular multiplication signals
    signal mod_res_enable       : STD_ULOGIC;
    signal mod_res_ready        : STD_ULOGIC;
    signal mod_res_result       : DATA;
    signal mod_res_input_a      : DATA;
    signal mod_res_input_b      : DATA;
    
    component modulus_multiplication 
        generic(
            C_block_size : integer := 256
        );
        port(
            clk             : in STD_ULOGIC;
            reset_n         : in STD_ULOGIC;

            enable_i            : in STD_ULOGIC;
            input_a             : in STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
            input_b             : in STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
            modulus             : in STD_ULOGIC_VECTOR(C_block_size-1 downto 0);

            output          : out STD_ULOGIC_VECTOR(C_block_size-1 downto 0);
            output_ready    : out STD_ULOGIC
        );
    end component modulus_multiplication;

    pure function get_index (x : unsigned) return integer is
    begin
        return to_integer(shift_right(x, 1) +1 );
    end function;

begin

    modulus_multiplication_inst: modulus_multiplication
    generic map(
        C_block_size => C_block_size
    )
    port map(
        clk => clk,
        reset_n => reset_n,
        enable_i => mod_res_enable,
        input_a => mod_res_input_a,
        input_b => mod_res_input_b,
        modulus => N,
        output => mod_res_result,
        output_ready => mod_res_ready
    );

    PROC_MANAGE_MULTIPLICATION : process (clk, reset_n)
    begin
        if (reset_n = '0') then
            mod_res_enable <= '0';
            mod_res_input_a <= (others => '0');
            mod_res_input_b <= (others => '0');
        elsif(rising_edge(clk)) then
            if(PRLM_en_mult = '1' and EXP_en_mult = '0') then
                mod_res_input_a <= PRLM_input_a;
                mod_res_input_b <= PRLM_input_b;
                mod_res_enable <= '1';
            elsif(EXP_en_mult = '1' and PRLM_en_mult = '0') then
                mod_res_input_a <= EXP_input_a;
                mod_res_input_b <= EXP_input_b;
                mod_res_enable <= '1';
            else 
                mod_res_enable <= '0';
                mod_res_input_a <= (others => '0');
                mod_res_input_b <= (others => '0');
            end if;
            if(mod_res_enable <= '1') then 
                mod_res_enable <= '0';
            end if;
        end if;
    end process;


    -- next state processes
    PROC_MM_NEXT_STATE : process (clk, reset_n)
    begin
        if (reset_n = '0') then
            MM_STATE_curr <= IDLE;
        elsif rising_edge(clk) then
            MM_STATE_curr <= MM_STATE_next;
        end if;
    end process;

    PROC_PRLMM_NEXT_STATE : process (clk, reset_n)
    begin
        if (reset_n = '0') then
            PRLMM_STATE_curr <= IDLE;
        elsif rising_edge(clk) then
            PRLMM_STATE_curr <= PRLMM_STATE_next;
        end if;
    end process;
    
    PROC_EXPM_NEXT_STATE : process (clk, reset_n)
    begin
        if (reset_n = '0') then
            EXPNM_STATE_curr <= IDLE;
        elsif rising_edge(clk) then
            EXPNM_STATE_curr <= EXPNM_STATE_next;
        end if;
    end process;

    -- combinatorial processes
    PROC_MM_COMB : process ( MM_STATE_curr, valid_in, pre_done, exp_done)
    begin
        ready_in <= '1';
        valid_out <= '0';
        result <= (others => '0');
        MM_STATE_next <= IDLE; 
        M <= (others => '0') ;
        K <= (others => '0');
        N <= (others => '0');
        case MM_STATE_curr is
            when IDLE =>
                if(valid_in = '1') then
                    MM_STATE_next <= PRE;
                    M <= message;
                    K <= key;
                    N <= modulus;
                end if;
            when PRE =>
                
                if(pre_done = '1') then
                    MM_STATE_next <= EXP;
                else
                    MM_STATE_next <= PRE;
                end if;
            when EXP => 
                if(exp_done = '1') then
                    MM_STATE_next <= DONE;
                else
                    MM_STATE_next <= PRE;
                end if;
            when DONE =>
                valid_out <= '1';
                result <= partial_res;
                if (ready_out = '1') then
                    MM_STATE_next <= IDLE;
                else 
                    MM_STATE_next <= DONE;
                end if;
            when others =>
                MM_STATE_next <= IDLE;
        end case;
    end process;

    PROC_PRLM_COMB : process ( MM_STATE_curr, PRLMM_STATE_curr)
        variable counter : unsigned( MATRIX_LENGHT downto 0) := (others => '0');
    begin
        M_MATRIX <= (others => (others => '0') );
        pre_done <= '0';
        PRLM_input_a <= (others => '0') ;
        PRLM_input_b <= (others => '0');
        PRLM_en_mult <= '0';
        PRLMM_STATE_next <= IDLE;
        case PRLMM_STATE_curr is
            when IDLE =>
                counter := (others => '0') ;
                if (MM_STATE_curr = PRE) then 
                    PRLMM_STATE_next <= WORKING;
                end if;

            when WORKING =>
                if (counter = 0) then
                    PRLM_input_a <= M;
                    PRLM_input_b <= M;
                    PRLM_en_mult <= '1';
                    --manage_mod_mult(message, message, '1', mod_res_input_a, mod_res_input_b, mod_res_enable);
                    PRLMM_STATE_next <= WAITING;
                elsif (counter = 1) then
                    PRLM_input_a <= M;
                    PRLM_input_b <= M_MATRIX(0);
                    PRLM_en_mult <= '1';
                    PRLMM_STATE_next <= WAITING;
                    --manage_mod_mult(message, M_MATRIX(0), '1', mod_res_input_a, mod_res_input_b, mod_res_enable); 
                elsif (counter < MATRIX_LENGHT) then
                    PRLM_input_a <= M_MATRIX(to_integer(counter));
                    PRLM_input_b <= M_MATRIX(0);
                    PRLM_en_mult <= '1';
                    --manage_mod_mult(M_MATRIX(to_integer(counter)), M_MATRIX(0), '1', mod_res_input_a, mod_res_input_b, mod_res_enable);
                    PRLMM_STATE_next <= WAITING;
                else 
                    PRLM_en_mult <= '0';
                    pre_done <= '1';
                    PRLMM_STATE_next <= DONE;
                end if;
            when WAITING =>
                PRLM_en_mult <= '0';
                if (mod_res_ready = '1') then
                    counter := counter + 1;
                    M_MATRIX(to_integer(counter)) <= mod_res_result;
                    PRLMM_STATE_next <= WORKING;
                end if;
            when DONE =>
                PRLMM_STATE_next <= DONE;
            when others => 
                PRLMM_STATE_next <= IDLE;
        end case;
    end process;

    PROC_EXPM_COMB : process (EXPNM_STATE_curr, MM_STATE_curr)
    
        variable window         : STD_ULOGIC_VECTOR(D-1 downto 0) := (others => '0');
        variable current_pos    : unsigned( log2c(C_BLOCK_SIZE)-1 downto 0) := (others => '1')  ;
        variable temp_window    : STD_ULOGIC_VECTOR(D-1 downto 0) := (others => '0') ;
        variable shft_key       : DATA;
        variable window_length  : unsigned(log2c(D) downto 0);
        variable is_mult_NW     : STD_ULOGIC;
    begin
        partial_res <= (others => '0');
        EXP_input_a <= (others => '0');
        EXP_input_b <= (others => '0');
        EXP_en_mult <= '0';
        exp_done <= '0';
        window      := (others => '0');
        temp_window := (others => '0');
        is_mult_NW  := '0';
        window_length := (others => '0') ;
        EXPNM_STATE_next <= IDLE;
        case EXPNM_STATE_curr is
            when IDLE =>
                current_pos := (others => '0');
                shft_key    := K;
                if(MM_STATE_curr = EXP) then
                    EXPNM_STATE_next <= SRCH_BGN;
                end if;
            when SRCH_BGN => 
                if(shft_key(C_BLOCK_SIZE-1) = '0') then 
                    EXPNM_STATE_next <= SRCH_BGN;
                    current_pos := current_pos -1;
                    shft_key    := DATA(shift_left(unsigned(shft_key), 1));
                else
                    EXPNM_STATE_next <= NW_WINDOW; 
                end if;
            when NW_WINDOW =>
                temp_window := shft_key(C_BLOCK_SIZE-1 downto C_block_size-D);
                if(temp_window(2 downto 1) = "00") then
                    window := "0001";
                    window_length := TO_UNSIGNED(1, window_length'length);
                elsif(temp_window(0) = '1') then 
                    window := temp_window;
                    window_length := TO_UNSIGNED(4, window_length'length);
                elsif(temp_window(1 downto 0) = "00") then
                    window := "0011";
                    window_length := TO_UNSIGNED(2, window_length'length);
                else
                    window := "0101";
                    window_length := TO_UNSIGNED(3, window_length'length);
                end if;                        
                if(partial_res = STD_ULOGIC_VECTOR(TO_UNSIGNED(0, partial_res'length))) then
                    partial_res <= M_MATRIX(get_index(unsigned(window)));

                    shft_key := DATA(SHIFT_LEFT(unsigned(shft_key), TO_INTEGER(window_length)));
                    if(shft_key(C_BLOCK_SIZE-1 ) = '1') then
                        EXPNM_STATE_next <= NW_WINDOW;
                    else
                        EXPNM_STATE_next <= ZW;
                    end if;
                else 
                    EXPNM_STATE_next <= WAITING_NW_MULT;
                end if;
            when WAITING_NW_MULT =>
                if(is_mult_NW = '0' and window_length > 0) then
                    
                    EXP_input_a <= partial_res;
                    EXP_input_b <= partial_res;
                    EXP_en_mult <= '1';
                    --manage_mod_mult(partial_res, partial_res, '1', mod_res_input_a, mod_res_input_b, mod_res_enable);
                    is_mult_NW := '1';
                    window_length := window_length -1;
                else 
                    EXP_en_mult <= '0';
                end if;
                
                if(mod_res_ready = '1') then
                    is_mult_NW := '0';
                    partial_res <= mod_res_result;
                    if(window_length > 0) then 
                        EXPNM_STATE_next <= WAITING_NW_MULT;
                    else 
                        EXPNM_STATE_next <= NW_EXP;
                    end if;
                else 
                    EXPNM_STATE_next <= WAITING_NW_MULT;
                end if;
            when NW_EXP => 
                
                EXP_input_a <= partial_res;
                EXP_input_b <= M_MATRIX(get_index(unsigned(window)));
                EXP_en_mult <= '1';
                --manage_mod_mult(partial_res, M_MATRIX(get_index(unsigned(window))), '1', mod_res_input_a, mod_res_input_b, mod_res_enable); --insert here correct 
                window := (others => '0');
                temp_window := (others => '0');
                window_length := TO_UNSIGNED(0, window_length'length);
                EXPNM_STATE_next <= WAITING;

            when ZW =>
                EXP_input_a <= partial_res;
                EXP_input_b <= partial_res;
                EXP_en_mult <= '1';
                --manage_mod_mult(partial_res, partial_res, '1', mod_res_input_a, mod_res_input_b, mod_res_enable);
                if(shft_key(C_BLOCK_SIZE-1) = '0') then
                    current_pos := current_pos -1;
                    shft_key    := DATA(shift_left(unsigned(shft_key), 1));
                end if;
                EXPNM_STATE_next <= WAITING;
                null;
            when WAITING =>
                EXP_en_mult <= '0';
                --manage_mod_mult((others => '0'), (others => '0'), '0', mod_res_input_a, mod_res_input_b, mod_res_enable);
                if(mod_res_ready = '1') then
                    partial_res <= mod_res_result;
                    if(current_pos = 0) then
                        EXPNM_STATE_next <= DONE;
                    elsif(shft_key(C_BLOCK_SIZE-1) = '0') then
                        EXPNM_STATE_next <= ZW;
                    elsif(shft_key(C_BLOCK_SIZE-1) = '1') then
                        EXPNM_STATE_next <= NW_WINDOW; 
                    end if;
                else 
                    EXPNM_STATE_next <= WAITING;
                end if;
            when DONE =>
                exp_done <= '1';
            when others =>
                EXPNM_STATE_next <= IDLE;
        end case;
    end process;
end architecture;
