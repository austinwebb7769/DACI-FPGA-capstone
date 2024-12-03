library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UART_Rx is
    Port (
        i_Clk      : in  STD_LOGIC;                    -- 50 MHz clock
        i_Rst_L    : in  STD_LOGIC;                    -- reset
        rx_serial  : in  STD_LOGIC;                    -- UART serial input
        rx_data    : out STD_LOGIC_VECTOR(7 downto 0); -- 8-bit received data
        rx_ready   : out STD_LOGIC                     -- data ready flag
    );
end UART_Rx;

architecture Behavioral of UART_Rx is
    constant BAUD_DIVISOR : integer := 5208;              -- For 9600 baud with 50 MHz clock
    signal baud_counter   : integer := 0;
    signal bit_counter    : integer := 0;
    signal rx_shift       : STD_LOGIC_VECTOR(9 downto 0); -- Shift register
    signal sampling       : STD_LOGIC := '0';
    signal rx_ready_internal : STD_LOGIC := '0';          -- Internal signal for rx_ready
begin
    -- Drive the rx_ready port using the internal signal
    rx_ready <= rx_ready_internal;

    process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            if i_Rst_L = '0' then
                baud_counter <= 0;
                bit_counter <= 0;
                rx_ready_internal <= '0';
                sampling <= '0';
            elsif rx_ready_internal = '1' then
                -- Clear ready signal once data is read
                rx_ready_internal <= '0';
            elsif sampling = '0' and rx_serial = '0' then
                -- Start bit detected
                sampling <= '1';
                baud_counter <= BAUD_DIVISOR / 2;           -- Start mid-bit sampling
                bit_counter <= 0;
            elsif sampling = '1' then
                if baud_counter = BAUD_DIVISOR - 1 then
                    baud_counter <= 0;
                    rx_shift(bit_counter) <= rx_serial;     -- Capture each bit
                    bit_counter <= bit_counter + 1;

                    -- Complete reception of 10 bits (start, 8 data, stop)
                    if bit_counter = 10 then
                        rx_data <= rx_shift(8 downto 1);    -- Extract 8-bit data
                        rx_ready_internal <= '1';          -- Set ready flag
                        sampling <= '0';
                    end if;
                else
                    baud_counter <= baud_counter + 1;
                end if;
            end if;
        end if;
    end process;
end Behavioral;
