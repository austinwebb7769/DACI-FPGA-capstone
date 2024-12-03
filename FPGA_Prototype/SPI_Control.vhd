library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SPI_Control is
  port (
    i_Rst_L    : in  std_logic;                -- Reset (Active Low)
    i_Clk      : in  std_logic;                -- 50 MHz FPGA Clock
    o_SPI_SCLK : out std_logic;                -- SPI Clock (SCLK)
    o_SPI_MOSI : out std_logic;                -- Master Out Slave In (MOSI)
    i_SPI_MISO : in  std_logic;                -- Master In Slave Out (MISO)
    o_SPI_SS   : out std_logic_vector(4 downto 0); -- Slave Select (5 slaves, active low)
    i_Data     : in  std_logic_vector(7 downto 0); -- Data to transmit
    o_Data     : out std_logic_vector(7 downto 0); -- Data received
    o_Done     : out std_logic                 -- Transfer done signal
  );
end entity SPI_Control;

architecture Behavioral of SPI_Control is

  -- Constants and internal signals
  constant CLK_DIVIDER : integer := 16;         -- Adjust for SPI clock frequency
  signal clk_div_count : integer range 0 to CLK_DIVIDER - 1 := 0;
  signal spi_clk       : std_logic := '0';      -- SPI clock signal
  signal bit_counter   : integer range 0 to 7 := 0; -- Tracks transmitted bits
  signal slave_index   : integer range 0 to 4 := 0; -- Tracks active slave
  signal cycle_count   : integer range 0 to 127 := 0; -- Tracks SPI cycles
  signal transmit_data : std_logic_vector(7 downto 0) := (others => '0');
  signal received_data : std_logic_vector(7 downto 0) := (others => '0');
  signal ss_signals    : std_logic_vector(4 downto 0) := (others => '1'); -- All slaves inactive by default

begin

  -- Clock divider process for SPI clock
  process(i_Clk, i_Rst_L)
  begin
    if i_Rst_L = '0' then
      clk_div_count <= 0;
      spi_clk <= '0';
    elsif rising_edge(i_Clk) then
      if clk_div_count = CLK_DIVIDER - 1 then
        spi_clk <= not spi_clk;
        clk_div_count <= 0;
      else
        clk_div_count <= clk_div_count + 1;
      end if;
    end if;
  end process;

  o_SPI_SCLK <= spi_clk;

  -- SPI Master logic
  process(spi_clk, i_Rst_L)
  begin
    if i_Rst_L = '0' then
      bit_counter <= 0;
      cycle_count <= 0;
      slave_index <= 0;
      ss_signals <= (others => '1'); -- Deactivate all slaves
      received_data <= (others => '0');
      o_Done <= '0';
    elsif rising_edge(spi_clk) then
      -- Begin SPI transaction
      if bit_counter < 8 then
        -- Transmit and receive data bit-by-bit
        o_SPI_MOSI <= transmit_data(7 - bit_counter); -- MSB first
        received_data(7 - bit_counter) <= i_SPI_MISO; -- Capture MISO
        bit_counter <= bit_counter + 1;
        o_Done <= '0';
      else
        -- End of 8-bit transaction
        bit_counter <= 0;
        o_Done <= '1';

        -- Increment cycle counter and switch slaves after 128 cycles
        if cycle_count = 127 then
          cycle_count <= 0;
          slave_index <= (slave_index + 1) mod 5; -- Cycle through slaves 0-4
          ss_signals <= (others => '1'); -- Deactivate all slaves
          ss_signals(slave_index) <= '0'; -- Activate current slave
        else
          cycle_count <= cycle_count + 1;
        end if;
      end if;
    end if;
  end process;

  -- Assign outputs
  o_SPI_SS <= ss_signals;
  o_Data <= received_data;

end Behavioral;
