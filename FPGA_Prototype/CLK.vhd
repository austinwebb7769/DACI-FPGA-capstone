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
    i_Data     : in  std_logic;          -- Data to transmit (bit by bit)
    o_Data     : out std_logic;          -- Data received (bit by bit)
    o_SCLK_Out : out std_logic;          -- Output for SPI clock for monitoring
    o_Received : out std_logic           -- Output for received bit (MISO) for monitoring
  );
end entity CLK;


architecture Behavioral of CLK is

  -- Signal declarations
  constant clk_hz : integer := 50e6;
  constant clk_period : time := 1 sec / clk_hz;
  
  signal clk_div      : std_logic := '0';               -- Clock divider signal for SPI clock
  signal sclk         : std_logic := '0';               -- Internal SPI clock
  signal ss_0         : std_logic := '1';               -- Slave Select for Slave 0 (active low)
  signal ss_1         : std_logic := '1';               -- Slave Select for Slave 1 (active low)
  signal bit_counter  : integer range 0 to 127 := 0;    -- Bit counter for tracking 128 cycles
  signal cycle_count  : integer range 0 to 127 := 0;    -- Count SPI cycles (128 cycles to switch SS)
  signal received_bit : std_logic := '0';               -- Bit received from MISO
  signal mosi_signal  : std_logic := '0';               -- Internal signal for MOSI
  signal clk_counter  : integer range 0 to 1 := 0;      -- Clock counter for SPI clock
  signal GND_Definition : std_logic := '0';
  signal GND_US : std_logic := '0';

begin

  -- Clock divider process for SPI clock
  process(i_Clk, i_Rst_L)
  begin
    if i_Rst_L = '0' then
      clk_counter <= 0;
      sclk<='0';
	 elsif(i_Clk='1') then
			clk_counter <=clk_counter+1;
		if (clk_counter = 2) then
			sclk <= NOT sclk;
			clk_counter <= 0;
		end if;
    end if;
  end process;  
	 
  o_SCLK_Out <= i_Clk; -- Expose the SPI clock output for monitoring
  GND_US <= GND_Definition;

  -- SPI Master process for handling slave select switching and bit counting
  process(i_Clk, i_Rst_L)
  begin
    if i_Rst_L = '0' then
      bit_counter <= 0;
      cycle_count <= 0;
      ss_0 <= '1';  -- Deactivate Slave 0
      ss_1 <= '1';  -- Deactivate Slave 1
    elsif rising_edge(i_Clk) then
      -- Increment bit counter
      if sclk = '1' then  -- Only count when the SPI clock is high
        bit_counter <= bit_counter + 1;
      end if;

      -- Toggle SS every 128 cycles
      if bit_counter = 127 then
        bit_counter <= 0;
        cycle_count <= cycle_count + 1;

        -- Alternate between slave selects
        if ss_0 = '1' then
          ss_0 <= '0';  -- Select Slave 0 (active low)
          ss_1 <= '1';  -- Deselect Slave 1
        else
          ss_0 <= '1';  -- Deselect Slave 0
          ss_1 <= '0';  -- Select Slave 1 (active low)
        end if;
      end if;
    end if;
  end process;
  
  -- Assign slave select outputs
  o_SPI_SS <= ss_0;  -- Output for Slave 0
  o_SPI_SS_1 <= ss_1; -- Output for Slave 1

  -- SPI data transmission
  process(i_Clk, i_Rst_L)
  begin
    if i_Rst_L = '0' then
      mosi_signal <= '0';
      received_bit <= '0';
    elsif rising_edge(i_Clk) then
      if sclk = '1' then
        -- Transmit data bit-by-bit via MOSI
        mosi_signal <= i_Data;
        
        -- Receive data bit-by-bit via MISO
        received_bit <= i_SPI_MISO;
      end if;
    end if;
  end process;

  o_SPI_MOSI <= mosi_signal;
  o_Data <= received_bit;
  o_Received <= received_bit; -- Expose received bit (MISO) output for monitoring

end Behavioral;