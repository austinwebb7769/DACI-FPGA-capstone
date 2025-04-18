library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPI_Control is
    port (
        i_Clk       : in  std_logic;
        i_Reset     : in  std_logic;
        i_START     : in  std_logic;

        i_BUSY      : in  std_logic;
        i_DOUTA_1   : in  std_logic;
        i_DOUTA_2   : in  std_logic;

        o_SCLK      : out std_logic;
        o_CONVST    : out std_logic;
        o_CS        : out std_logic_vector(1 downto 0); -- CS(0) = ADC1, CS(1) = ADC2

        o_Data1     : out std_logic_vector(127 downto 0);
        o_Data2     : out std_logic_vector(127 downto 0);
        o_Done      : out std_logic
    );
end SPI_Control;

architecture Behavioral of SPI_Control is

    type t_State is (
        IDLE, CONVERT_START, WAIT_BUSY_HIGH, WAIT_BUSY_LOW,
        READ_ADC1, READ_ADC2, DONE
    );
    signal r_State : t_State := IDLE;

    signal r_CONVST      : std_logic := '1';
    signal r_CS          : std_logic_vector(1 downto 0) := (others => '1');
    signal r_SCLK        : std_logic := '0';
    signal r_SCLK_prev   : std_logic := '0';

    signal clk_div       : integer := 0;
    constant CLK_DIV_MAX : integer := 4; -- Adjust for simulation speed if needed

    signal bit_index     : integer range 0 to 127 := 0;
    signal r_Data1       : std_logic_vector(127 downto 0) := (others => '0');
    signal r_Data2       : std_logic_vector(127 downto 0) := (others => '0');
    signal r_Done        : std_logic := '0';

    signal sclk_enable   : std_logic := '0';

begin

    -- Output assignments
    o_CONVST <= r_CONVST;
    o_CS     <= r_CS;
    o_SCLK   <= r_SCLK;
    o_Data1  <= r_Data1;
    o_Data2  <= r_Data2;
    o_Done   <= r_Done;

    -- SCLK generation
    process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            if sclk_enable = '1' then
                if clk_div = CLK_DIV_MAX then
                    r_SCLK <= not r_SCLK;
                    clk_div <= 0;
                else
                    clk_div <= clk_div + 1;
                end if;
            else
                r_SCLK <= '0';
                clk_div <= 0;
            end if;
        end if;
    end process;

    -- FSM
    process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            r_SCLK_prev <= r_SCLK;

            if i_Reset = '1' then
                r_State     <= IDLE;
                r_CONVST    <= '1';
                r_CS        <= (others => '1');
                r_Done      <= '0';
                sclk_enable <= '0';
                bit_index   <= 0;
                r_Data1     <= (others => '0');
                r_Data2     <= (others => '0');
                r_SCLK_prev <= '0';
            else
                case r_State is

                    when IDLE =>
                        r_Done <= '0';
                        if i_START = '1' then
                            r_CONVST <= '0';
                            r_State  <= CONVERT_START;
                        end if;

                    when CONVERT_START =>
                        r_CONVST <= '1';
                        if i_BUSY = '1' then
                            r_State <= WAIT_BUSY_LOW;
                        else
                            r_State <= WAIT_BUSY_HIGH;
                        end if;

                    when WAIT_BUSY_HIGH =>
                        if i_BUSY = '1' then
                            r_State <= WAIT_BUSY_LOW;
                        end if;

                    when WAIT_BUSY_LOW =>
                        if i_BUSY = '0' then
                            r_CS(0) <= '0'; -- Select ADC1
                            r_CS(1) <= '1';
                            bit_index <= 0;
                            sclk_enable <= '1';
                            r_State <= READ_ADC1;
                        end if;

                    when READ_ADC1 =>
                        if r_SCLK = '1' and r_SCLK_prev = '0' then
                            r_Data1(127 - bit_index) <= i_DOUTA_1;
                            if bit_index = 127 then
                                r_CS(0) <= '1';
                                r_CS(1) <= '0'; -- Select ADC2
                                bit_index <= 0;
                                r_State <= READ_ADC2;
                            else
                                bit_index <= bit_index + 1;
                            end if;
                        end if;

                    when READ_ADC2 =>
                        if r_SCLK = '1' and r_SCLK_prev = '0' then
                            r_Data2(127 - bit_index) <= i_DOUTA_2;
                            if bit_index = 127 then
                                sclk_enable <= '0';
                                r_CS <= (others => '1');
                                r_State <= DONE;
                            else
                                bit_index <= bit_index + 1;
                            end if;
                        end if;

                    when DONE =>
                        r_Done <= '1';
                        r_State <= IDLE;

                    when others =>
                        r_State <= IDLE;
                end case;
            end if;
        end if;
    end process;

end Behavioral;
