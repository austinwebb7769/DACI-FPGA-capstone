library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UART_Rx is
    Port (
        i_Clk      : in  STD_LOGIC;                    -- 50 MHz clock
        i_Rst_L    : in  STD_LOGIC;                    -- Active-low reset
        i_Rx_Serial : in  STD_LOGIC;                   -- UART serial input
        o_Rx_Data   : out STD_LOGIC_VECTOR(7 downto 0); -- 8-bit received data
        o_Rx_Ready  : out STD_LOGIC                     -- Data ready flag
    );
end UART_Rx;

architecture Behavioral of UART_Rx is
    constant c_BAUD_RATE    : integer := 9600;
    constant c_CLKS_PER_BIT : integer := 50000000 / c_BAUD_RATE;  -- Baud rate divisor

    type t_State is (IDLE, START_BIT, DATA_BITS, STOP_BIT, DONE);
    signal r_State : t_State := IDLE;

    signal r_Clk_Count : integer range 0 to c_CLKS_PER_BIT := 0;
    signal r_Bit_Index : integer range 0 to 7 := 0;
    signal r_Rx_Buffer : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal r_Rx_Ready  : STD_LOGIC := '0';

begin
    process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            if i_Rst_L = '0' then
                r_State     <= IDLE;
                r_Clk_Count <= 0;
                r_Bit_Index <= 0;
                r_Rx_Ready  <= '0';
            else
                case r_State is
                    when IDLE =>
                        o_Rx_Ready <= '0';
                        if i_Rx_Serial = '0' then -- Start bit detected
                            r_State     <= START_BIT;
                            r_Clk_Count <= c_CLKS_PER_BIT / 2; -- Mid-bit sample
                        end if;

                    when START_BIT =>
                        if r_Clk_Count < c_CLKS_PER_BIT - 1 then
                            r_Clk_Count <= r_Clk_Count + 1;
                        else
                            r_Clk_Count <= 0;
                            r_Bit_Index <= 0;
                            r_State     <= DATA_BITS;
                        end if;

                    when DATA_BITS =>
                        if r_Clk_Count < c_CLKS_PER_BIT - 1 then
                            r_Clk_Count <= r_Clk_Count + 1;
                        else
                            r_Clk_Count                 <= 0;
                            r_Rx_Buffer(r_Bit_Index)    <= i_Rx_Serial;
                            if r_Bit_Index < 7 then
                                r_Bit_Index <= r_Bit_Index + 1;
                            else
                                r_State <= STOP_BIT;
                            end if;
                        end if;

                    when STOP_BIT =>
                        if r_Clk_Count < c_CLKS_PER_BIT - 1 then
                            r_Clk_Count <= r_Clk_Count + 1;
                        else
                            r_Clk_Count <= 0;
                            r_State     <= DONE;
                        end if;

                    when DONE =>
                        o_Rx_Data  <= r_Rx_Buffer;
                        o_Rx_Ready <= '1';
                        r_State    <= IDLE;
                
                    when others =>
                        r_State <= IDLE;
                end case;
            end if;
        end if;
    end process;
    
    o_Rx_Ready <= r_Rx_Ready;
end Behavioral;
