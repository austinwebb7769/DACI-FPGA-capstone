library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UART_Tx is
    Port (
        i_Clk       : in  STD_LOGIC;  
        i_Tx_Enable : in  STD_LOGIC;  
        o_Tx_Serial : out STD_LOGIC := '1';  
        o_Tx_Done   : out STD_LOGIC := '0'   
    );
end UART_Tx;

architecture Behavioral of UART_Tx is
    constant c_BAUD_RATE    : integer := 9600;
    constant c_CLKS_PER_BIT : integer := 50000000 / 9600;  

    type t_State is (IDLE, START_BIT, DATA_BITS, STOP_BIT1, STOP_BIT2, DONE);
    signal r_State : t_State := IDLE;

    signal r_Clk_Count : integer range 0 to c_CLKS_PER_BIT := 0;
    signal r_Bit_Index : integer range 0 to 7 := 0;
    signal r_Tx_Buffer : std_logic_vector(7 downto 0) := (others => '0');
    signal r_Tx_Serial : std_logic := '1';
    signal r_Tx_Busy   : std_logic := '0';
    signal r_Byte_Sent : integer range 0 to 1 := 0;

begin
    process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            case r_State is
                when IDLE =>
                    r_Tx_Serial <= '1';
                    o_Tx_Done   <= '0';

                    if i_Tx_Enable = '1' and r_Tx_Busy = '0' then
                        
                        r_Tx_Buffer <= "10000000"; -- First byte (131)
                        report "Loading First Byte: 00000011" severity note;

                        r_Tx_Busy    <= '1';
                        r_Clk_Count  <= 0;
                        r_Bit_Index  <= 0;
                        r_State      <= START_BIT;
						  else
						      r_State      <= IDLE;
                    end if;

                when START_BIT =>
                    r_Tx_Serial <= '0';
                    report "Start Bit Sent" severity note;

                    if r_Clk_Count < c_CLKS_PER_BIT - 1 then
                        r_Clk_Count <= r_Clk_Count + 1;
								r_State     <= START_BIT;
                    else
                        r_Clk_Count <= 0;
                        r_State     <= DATA_BITS;
                    end if;

                when DATA_BITS =>
                    r_Tx_Serial <= r_Tx_Buffer(r_Bit_Index);
                    report "Bit " & integer'image(r_Bit_Index) & " Sent = " & std_logic'image(r_Tx_Buffer(r_Bit_Index)) severity note;

                    if r_Clk_Count < c_CLKS_PER_BIT - 1 then
                        r_Clk_Count <= r_Clk_Count + 1;
								r_State     <= DATA_BITS;
                    else
                        r_Clk_Count <= 0;
								
								--Check if we have sent out all bits
                        if r_Bit_Index < 7 then
                            r_Bit_Index <= r_Bit_Index + 1;
									 r_State     <= DATA_BITS;
                        else
                            r_Bit_Index <= 0;
                            r_State     <= STOP_BIT1;
                        end if;
                    end if;

                when STOP_BIT1 =>
                    r_Tx_Serial <= '1';
                    report "Stop Bit 1 Sent" severity note;

                    if r_Clk_Count < c_CLKS_PER_BIT - 1 then
                        r_Clk_Count <= r_Clk_Count + 1;
								r_State     <= STOP_BIT1;
                    else
                        r_Clk_Count <= 0;
                        r_State     <= STOP_BIT2;
                    end if;

                when STOP_BIT2 =>
                    r_Tx_Serial <= '1';
                    report "Stop Bit 2 Sent" severity note;

                    if r_Clk_Count < c_CLKS_PER_BIT - 1 then
                        r_Clk_Count <= r_Clk_Count + 1;
								r_State     <= STOP_BIT2;
                    else
                        r_Clk_Count <= 0;
                        r_State     <= DONE;
                    end if;

                when DONE =>
                    o_Tx_Done   <= '1';
                    r_Tx_Busy   <= '0';
                    r_Byte_Sent <= 0;
                    r_State     <= IDLE;
                    report "Transmission Complete" severity note;
						  
					 when others =>
						  r_State  <= IDLE;
						  
            end case;
        end if;
    end process;

    o_Tx_Serial <= r_Tx_Serial;

end Behavioral;