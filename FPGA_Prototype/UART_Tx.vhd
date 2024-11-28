library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UART_Tx is
    Port (
        i_Clk    : in  STD_LOGIC;                    -- 50 MHz clock
        i_Rst_L  : in  STD_LOGIC;                    -- reset
        tx_start : in  STD_LOGIC;                    -- start transmission
        tx_data  : in  STD_LOGIC_VECTOR(7 downto 0); -- 8-bit data
        tx_busy  : out STD_LOGIC;                    -- busy flag
        tx_serial: out STD_LOGIC                     -- UART serial output
    );
end UART_Tx;

architecture Behavioral of UART_Tx is
    constant BAUD_DIVISOR : integer := 5208;              -- For 9600 baud with 50 MHz clock
    signal baud_counter   : integer := 0;
    signal bit_counter    : integer := 0;
    signal tx_reg         : STD_LOGIC_VECTOR(9 downto 0); -- 1 start, 8 data, 1 stop
    signal tx_active      : STD_LOGIC := '0';

begin
    process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            if i_Rst_L = '1' then
                baud_counter <= 0;
                bit_counter <= 0;
                tx_serial <= '1';
                tx_busy <= '0';
                tx_active <= '0';
            elsif tx_start = '1' and tx_busy = '0' then
                -- Load data and start transmission
                tx_reg <= '0' & tx_data & '1';                -- Start bit, data, stop bit
                tx_busy <= '1';
                tx_active <= '1';
                baud_counter <= 0;
                bit_counter <= 0;
            elsif tx_active = '1' then
                -- Handle baud timing
                if baud_counter = BAUD_DIVISOR - 1 then
                    baud_counter <= 0;
                    tx_serial <= tx_reg(bit_counter);         -- Send each bit
                    bit_counter <= bit_counter + 1;
                    
                    -- Transmission complete
                    if bit_counter = 10 then
                        tx_busy <= '0';
                        tx_active <= '0';
                        bit_counter <= 0;
                        tx_serial <= '1';                    -- Idle high
                    end if;
                else
                    baud_counter <= baud_counter + 1;
                end if;
            end if;
        end if;
    end process;
end Behavioral;

