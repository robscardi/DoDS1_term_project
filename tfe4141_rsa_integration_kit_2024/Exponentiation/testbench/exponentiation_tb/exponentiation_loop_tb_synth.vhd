library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
USE std.textio.ALL;

-- Test multiple inputs generated and read from exponentiation_loop_tb.txt

entity exponentiation_loop_tb_synth is
end exponentiation_loop_tb_synth;

architecture Behavioral of exponentiation_loop_tb_synth is
    constant C_block_size : integer := 256;
    CONSTANT CLOCK_PERIOD : TIME := 10 ns;
    
    -- Input signals to DUT
    signal tb_valid_in     : std_ulogic := '0';
    signal tb_ready_in     : std_ulogic;
    signal tb_message      : std_ulogic_vector(C_block_size-1 downto 0) := (others => '0');
    signal tb_key          : std_ulogic_vector(C_block_size-1 downto 0) := (others => '0');
    signal tb_modulus      : std_ulogic_vector(C_block_size-1 downto 0) := (others => '0');

    -- Output signals from DUT
    signal tb_ready_out    : std_ulogic := '1';
    signal tb_valid_out    : std_ulogic;
    signal tb_result       : std_ulogic_vector(C_block_size-1 downto 0);

    -- Clock and Reset
    signal tb_clk          : std_ulogic := '0';
    signal tb_reset_n      : std_ulogic := '1';
    
    signal correct_res : std_ulogic_vector(C_block_size-1 downto 0);

begin

    uut: entity work.exponentiation
        port map (
            valid_in    => tb_valid_in,
            ready_in    => tb_ready_in,
            message     => tb_message,
            key         => tb_key,
            ready_out   => tb_ready_out,
            valid_out   => tb_valid_out,
            result      => tb_result,
            modulus     => tb_modulus,
            clk         => tb_clk,
            reset_n     => tb_reset_n
        );

    -- Clock process
    PROC_CLK : process is
    begin
        WAIT FOR CLOCK_PERIOD/2;
        tb_clk <= NOT tb_clk;
    end process;

    Stimulus : process
        file txt_file : text;
        variable line_data : line;
        variable hex_string : std_ulogic_vector(C_block_size-1 downto 0);  -- 256-bit value in hexadecimal (64 hex digits)
        variable line_count : integer := 0;   

    begin

        file_open(txt_file, "exponentiation_loop_tb.txt", read_mode);
            
            tb_reset_n <= '0';   
            wait for 2*CLOCK_PERIOD;   
            tb_reset_n <= '1';   
            wait for 1*CLOCK_PERIOD;
            while not endfile(txt_file) loop
                readline(txt_file, line_data);
                hread(line_data, hex_string);
                wait for CLOCK_PERIOD;
                -- Skip blank lines
            if hex_string(0) /= 'U' then
                case line_count is
                    when 0 =>
                        -- First line: assign to key
                        tb_key <= hex_string;
                    when 1 =>
                        -- Second line: assign to modulus
                        tb_modulus <= hex_string;
                    when others =>
                        if line_count mod 2 = 0 then
                            tb_message <= hex_string;
                        else
                            correct_res <= hex_string;
                            tb_valid_in <= '1';
                            WAIT UNTIL tb_valid_out = '1';
                            tb_valid_in <= '0';
                            assert correct_res = tb_result
                                report "TEST FAILED" severity failure;
                        end if;
                end case;
                -- Increment line count
                line_count := line_count + 1;
            end if;
        end loop;

        file_close(txt_file);
                assert false report "TEST SUCCESSFUL" severity failure;
        wait;
    end process;

end Behavioral;
