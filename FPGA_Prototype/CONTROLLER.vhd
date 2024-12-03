library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CONTROLLER is
    port (
        i_CLK       : in  std_logic;
        i_RST       : in  std_logic;
        i_SPI       : in  std_logic; -- SPI MISO
        i_UART      : in  std_logic; -- UART RX
        o_RST       : out std_logic;
        o_SPI_SCLK  : out std_logic; -- SPI clock
        o_SPI_MOSI  : out std_logic; -- SPI MOSI
        o_UART      : out std_logic; -- UART TX
        o_SEL_SPI   : out std_logic_vector(4 downto 0); -- SPI Slave Select (5 slaves)
        o_SEL_UART  : out std_logic; -- UART selector (e.g., TX enable)
        o_UART_BUSY : out std_logic  -- UART busy signal
    );
end entity CONTROLLER;

architecture RTL of CONTROLLER is

    -- Internal signals
    signal spi_data_in    : std_logic_vector(7 downto 0) := (others => '0'); -- SPI Data received
    signal spi_data_out   : std_logic_vector(7 downto 0) := (others => '0'); -- SPI Data to transmit
    signal spi_done       : std_logic := '0';                                -- SPI transaction done
    signal uart_tx_start  : std_logic := '0';                                -- UART TX start signal
    signal uart_rx_ready  : std_logic := '0';                                -- UART RX ready signal
    signal uart_data_in   : std_logic_vector(7 downto 0) := (others => '0'); -- UART received data
    signal uart_data_out  : std_logic_vector(7 downto 0) := (others => '0'); -- UART data to transmit
    signal uart_busy      : std_logic := '0';                                -- UART TX busy signal

begin

    -- SPI Module Instance
    SPI_Inst: entity work.SPI_Control
        port map (
            i_Clk      => i_CLK,
            i_Rst_L    => i_RST,
            i_Data     => spi_data_out,
            o_Data     => spi_data_in,
            o_SPI_SCLK => o_SPI_SCLK,
            o_SPI_MOSI => o_SPI_MOSI,
            i_SPI_MISO => i_SPI,
            o_SPI_SS   => o_SEL_SPI,
            o_Done     => spi_done
        );

    -- UART Receiver Instance
    UART_RX_Inst: entity work.UART_Rx
        port map (
            i_Clk      => i_CLK,
            i_Rst_L    => i_RST,
            rx_serial  => i_UART,        -- UART RX input
            rx_data    => uart_data_in,  -- Received data from UART
            rx_ready   => uart_rx_ready  -- Indicates data is ready
        );

    -- UART Transmitter Instance
    UART_TX_Inst: entity work.UART_Tx
        port map (
            i_Clk      => i_CLK,
            i_Rst_L    => i_RST,
            tx_data    => uart_data_out, -- Data to send via UART
            tx_start   => uart_tx_start, -- Start transmission
            tx_busy    => uart_busy,     -- UART TX busy flag
            tx_serial  => o_UART         -- UART TX output
        );

    -- SPI to UART Data Flow Logic
    process(i_CLK, i_RST)
    begin
        if i_RST = '0' then
            spi_data_out <= (others => '0');    -- Reset SPI transmit data
            uart_data_out <= (others => '0');  -- Reset UART transmit data
            uart_tx_start <= '0';              -- Reset UART TX start signal
        elsif rising_edge(i_CLK) then
            -- When UART receives data, load it for SPI transmission
            if uart_rx_ready = '1' then
                spi_data_out <= uart_data_in;  -- Load received UART data into SPI
            end if;

            -- When SPI transaction completes, send received data via UART
            if spi_done = '1' and uart_busy = '0' then
                uart_data_out <= spi_data_in;  -- Load SPI received data for UART TX
                uart_tx_start <= '1';         -- Start UART transmission
            else
                uart_tx_start <= '0';         -- Clear UART TX start signal
            end if;
        end if;
    end process;

    -- Reset Output
    o_RST <= i_RST;

    -- UART Busy Output
    o_UART_BUSY <= uart_busy;

end architecture RTL;
