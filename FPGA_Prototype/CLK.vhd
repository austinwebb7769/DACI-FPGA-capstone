library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CLK is
  port (
    i_Rst_L    : in  std_logic;          -- Reset (Active Low)
    i_Clk      : in  std_logic;          -- 50 MHz FPGA Clock
    o_SPI_SCLK : out std_logic;          -- SPI Clock (SCLK)
    o_SPI_MOSI : out std_logic;          -- Master Out Slave In (MOSI)
    i_SPI_MISO : in  std_logic;          -- Master In Slave Out (MISO)
    o_SPI_SS   : out std_logic;          -- Slave Select for Slave 0
    o_SPI_SS_1 : out std_logic;          -- Slave Select for Slave 1
    i_Data     : in  std_logic_vector(7 downto 0); -- 8-bit data to transmit
    o_Data     : out std_logic_vector(7 downto 0); -- 8-bit data received
    o_SCLK_Out : out std_logic;          -- Output for SPI clock for monitoring
    o_Received : out std_logic           -- Output for received bit (MISO) for monitoring
  );
end entity CLK;

architecture Behavioral of CLK is

  -- Signal declarations
  constant clk_hz : integer := 50e6;
  constant spi_clk_divider : integer := 16;           -- Adjust for desired SPI clock frequency
  signal clk_div_counter   : integer range 0 to spi_clk_divider - 1 := 0; 
  signal sclk              : std_logic := '0';        -- Internal SPI clock
  signal ss_0              : std_logic := '1';        -- Slave Select for Slave 0 (active low)
  signal ss_1              : std_logic := '1';        -- Slave Select for Slave 1 (active low)
  signal bit_counter       : integer range 0 to 7 := 0;  -- 8-bit transmission counter
  signal cycle_count       : integer range 0 to 127 := 0; -- Count SPI cycles (128 cycles to switch SS)
  signal received_data     : std_logic_vector(7 downto 0) := (others => '0'); -- Received data storage
  signal transmit_data     : std_logic_vector(7 downto 0) := (others => '0'); -- Data to be sent
  signal mosi_signal       : std_logic := '0';        -- Internal signal for MOSI

begin

  -- Clock divider process for SPI clock
  process(i_Clk, i_Rst_L)
  begin
    if i_Rst_L = '0' then
      clk_div_counter <= 0;
      sclk <= '0';
    elsif rising_edge(i_Clk) then
      -- Divide the clock for SPI to achieve lower frequency
      if clk_div_counter = spi_clk_divider - 1 then
        sclk <= not sclk;
        clk_div_counter <= 0;
      else
        clk_div_counter <= clk_div_counter + 1;
      end if;
    end if;
  end process;

  o_SPI_SCLK <= sclk; -- Expose the divided SPI clock output for monitoring

  -- SPI Master process for handling slave select switching and cycle counting
  process(sclk, i_Rst_L)
  begin
    if i_Rst_L = '0' then
      bit_counter <= 0;
      cycle_count <= 0;
      ss_0 <= '1';  -- Deactivate Slave 0
      ss_1 <= '1';  -- Deactivate Slave 1
    elsif rising_edge(sclk) then
      -- Transmit bit by bit from `transmit_data` on MOSI and receive bit on MISO
      if bit_counter < 8 then
        mosi_signal <= transmit_data(7 - bit_counter); -- Transmit MSB first
        received_data(7 - bit_counter) <= i_SPI_MISO;  -- Receive into MSB first
        bit_counter <= bit_counter + 1;
      else
        bit_counter <= 0;
      end if;

      -- Toggle SS every 128 cycles
      if bit_counter = 0 then
        if cycle_count = 127 then
          cycle_count <= 0;
          -- Alternate between slave selects
          if ss_0 = '1' then
            ss_0 <= '0';  -- Select Slave 0 (active low)
            ss_1 <= '1';  -- Deselect Slave 1
          else
            ss_0 <= '1';  -- Deselect Slave 0
            ss_1 <= '0';  -- Select Slave 1 (active low)
          end if;
        else
          cycle_count <= cycle_count + 1;
        end if;
      end if;
    end if;
  end process;

  -- Assign slave select outputs
  o_SPI_SS <= ss_0;      -- Output for Slave 0
  o_SPI_SS_1 <= ss_1;    -- Output for Slave 1

  -- Data transmission and received data assignment
  o_SPI_MOSI <= mosi_signal;
  o_Data <= received_data; -- Expose received 8-bit data
  o_Received <= received_data(0); -- Output the LSB of received data for monitoring
  
end Behavioral;