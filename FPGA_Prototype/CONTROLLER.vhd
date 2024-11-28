library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CONTROLLER is
	port(
		i_CLK			:in std_logic;
		i_RST			:in std_logic;
		i_SPI			:in std_logic;
		i_UART		:in std_logic;
		o_RST			:out std_logic;
		o_SPI			:out std_logic;
		o_UART		:out std_logic;
		o_SEL_SPI	:out std_logic_vector(2 down to 0);
		o_SEL_UART	:out std_logic 
	);
	
end entity CONTROLLER;

architecture RTL of CONTROLLER is

signal cycle_count       : integer range 0 to 127 := 0; -- Count SPI cycles (128 cycles to switch SS)
signal ss					 : std_logic_vector(2 down to 0) := "000"; --Slave Select
signal ss_u					 : std_logic := 1; --TX/RX of UART

begin

	UART_RX_Inst: entity work.UART_Rx
	port map (
		i_Clk => 		i_CLK,
		i_Rst_L => 		i_RST,
		rx_data => 		i_UART,
		rx_ready => 	not o_SEL_UART);
		
	UART_TX_Inst: entity work.UART_Tx
	port map (
		i_Clk => 		i_CLK,
		i_Rst_L => 		i_RST,
		tx_data => 		o_UART,
		tx_start => 	o_SEL_UART);
		
	SPI_Inst: entity work.CLK
	port map (
		i_Clk => 		i_CLK,
		i_Rst_L => 		i_RST,
		o_SPI_SS => 	o_SEL_SPI,
		o_Data => 		i_SPI,    
		i_Data =>    	0);
		
	process(i_CLK)
	begin
		if rising_edge(i_CLK) then
			cycle_count <= cycle_count + 1
			if cycle_count = 127 then
				cycle_count <= 0
				case ss is
					when "000" =>
						ss <= "001";
					when "001" =>
						ss <= "010";
					when "010" =>
						ss <= "011";
					when "011" =>
						ss <= "100";
					when others =>
						ss <= "000"; --Default case
				end case;
			end if;
		end if;
		
	end process;
	
	o_SEL_SPI <= ss;
	o_SEL_UART <= ss_u;

end architecture RTL;