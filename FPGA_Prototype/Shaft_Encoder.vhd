library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Shaft_Encoder is
    Port (
        i_Clk         : in  STD_LOGIC;
        i_Reset       : in  STD_LOGIC;
        Channel_A     : in  STD_LOGIC;
        Channel_B     : in  STD_LOGIC;
        o_Pulse_Count : out STD_LOGIC_VECTOR(15 downto 0);
        o_Data_Ready  : out STD_LOGIC  -- Optional debug/output assist
    );
end Shaft_Encoder;

architecture Behavioral of Shaft_Encoder is

    type State_Type is (COUNTING, STORED);
    signal Current_State, Next_State : State_Type := COUNTING;

    signal pulse_count   : UNSIGNED(15 downto 0) := (others => '0');
    signal output_buffer : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal clk_count     : INTEGER := 0;
    signal prev_A        : STD_LOGIC := '0';
    signal data_ready    : STD_LOGIC := '0';

    constant CYCLE_LIMIT : INTEGER := 100000; -- 2ms at 50 MHz

begin

    -- Sequential process
    process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            if i_Reset = '1' then
                Current_State  <= COUNTING;
                pulse_count    <= (others => '0');
                clk_count      <= 0;
                prev_A         <= '0';
                output_buffer  <= (others => '0');
                data_ready     <= '0';
            else
                Current_State <= Next_State;

                -- Rising edge detection on Channel_A
                if Channel_A = '1' and prev_A = '0' then
                    pulse_count <= pulse_count + 1;
                end if;
                prev_A <= Channel_A;

                if Current_State = COUNTING then
                    if clk_count < CYCLE_LIMIT then
                        clk_count <= clk_count + 1;
                    end if;
                    data_ready <= '0';
                elsif Current_State = STORED then
                    output_buffer <= std_logic_vector(pulse_count);
                    pulse_count   <= (others => '0');
                    clk_count     <= 0;
                    data_ready    <= '1';
                end if;
            end if;
        end if;
    end process;

    -- FSM transition logic
    process(Current_State, clk_count)
    begin
        case Current_State is
            when COUNTING =>
                if clk_count >= CYCLE_LIMIT then
                    Next_State <= STORED;
                else
                    Next_State <= COUNTING;
                end if;
            when STORED =>
                Next_State <= COUNTING;
        end case;
    end process;

    o_Pulse_Count <= output_buffer;
    o_Data_Ready  <= data_ready;

end Behavioral;
