library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CONTROLLER is
    Port (
        i_Clk          : in  STD_LOGIC;
        i_Reset        : in  STD_LOGIC;
        i_Send_Trigger : in  STD_LOGIC; --Signal from Brooklynn

        -- SPI ADC Inputs
        i_BUSY         : in  STD_LOGIC;
        i_DOUTA_1      : in  STD_LOGIC;
        i_DOUTA_2      : in  STD_LOGIC;

        -- Encoder Inputs
        i_EncoderA     : in  STD_LOGIC;
        i_EncoderB     : in  STD_LOGIC;

        -- SPI Outputs
        o_CONVST       : out STD_LOGIC;
        o_CS           : out STD_LOGIC_VECTOR(1 downto 0);
        o_SCLK         : out STD_LOGIC;

        -- UART Serial Output
        o_Tx_Serial    : out STD_LOGIC;
        
        -- Debug
        o_Debug_State  : out STD_LOGIC_VECTOR(2 downto 0)
    );
end CONTROLLER;

architecture Behavioral of CONTROLLER is

    component SPI_Control
        Port (
            i_Clk      : in  STD_LOGIC;
            i_Reset    : in  STD_LOGIC;
            i_START    : in  STD_LOGIC;
            i_BUSY     : in  STD_LOGIC;
            i_DOUTA_1  : in  STD_LOGIC;
            i_DOUTA_2  : in  STD_LOGIC;
            o_SCLK     : out STD_LOGIC;
            o_CONVST   : out STD_LOGIC;
            o_CS       : out STD_LOGIC_VECTOR(1 downto 0);
            o_Data1    : out STD_LOGIC_VECTOR(127 downto 0);
            o_Data2    : out STD_LOGIC_VECTOR(127 downto 0);
            o_Done     : out STD_LOGIC
        );
    end component;

    component Shaft_Encoder
        Port (
            i_Clk         : in  STD_LOGIC;
            i_Reset       : in  STD_LOGIC;
            Channel_A     : in  STD_LOGIC;
            Channel_B     : in  STD_LOGIC;
            o_Pulse_Count : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    --------------------------------------------------------------------
    -- Signals
    --------------------------------------------------------------------
    signal adc_start       : STD_LOGIC := '0';
    signal adc_done        : STD_LOGIC;
    signal adc_data1       : STD_LOGIC_VECTOR(127 downto 0);
    signal adc_data2       : STD_LOGIC_VECTOR(127 downto 0);
    signal encoder_data    : STD_LOGIC_VECTOR(15 downto 0);
    signal buffer_34B      : STD_LOGIC_VECTOR(271 downto 0);

    signal byte_index      : INTEGER range 0 to 34 := 0;
    signal uart_bit_index  : INTEGER range 0 to 7 := 0;
    signal uart_clk_count  : INTEGER := 0;

    signal tx_byte         : STD_LOGIC_VECTOR(7 downto 0);
    signal r_Tx_Serial     : STD_LOGIC := '1';

    signal prev_trigger    : STD_LOGIC := '0';
    signal rising_edge_trig : STD_LOGIC := '0';

    --------------------------------------------------------------------
    -- Constants
    --------------------------------------------------------------------
    constant c_CLK  : integer := 50000000;
    constant c_BAUD_RATE    : integer := 9600;
    constant c_CLKS_PER_BIT : integer := 10; -- Fast simulation value

    --------------------------------------------------------------------
    -- State Machines
    --------------------------------------------------------------------
    type t_MainState is (IDLE, DATA_CAPTURE, LOAD_BYTE, START_BIT, DATA_BITS, STOP_BIT1, STOP_BIT2, NEXT_BYTE);
    signal state : t_MainState := IDLE;

begin

    --------------------------------------------------------------------
    -- Component Instantiations
    --------------------------------------------------------------------
    SPI_CTRL : SPI_Control
        port map (
            i_Clk      => i_Clk,
            i_Reset    => i_Reset,
            i_START    => adc_start,
            i_BUSY     => i_BUSY,
            i_DOUTA_1  => i_DOUTA_1,
            i_DOUTA_2  => i_DOUTA_2,
            o_SCLK     => o_SCLK,
            o_CONVST   => o_CONVST,
            o_CS       => o_CS,
            o_Data1    => adc_data1,
            o_Data2    => adc_data2,
            o_Done     => adc_done
        );

    SHAFT : Shaft_Encoder
        port map (
            i_Clk         => i_Clk,
            i_Reset       => i_Reset,
            Channel_A     => i_EncoderA,
            Channel_B     => i_EncoderB,
            o_Pulse_Count => encoder_data
        );

    --------------------------------------------------------------------
    -- Trigger Edge Detection
    --------------------------------------------------------------------
    process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            prev_trigger     <= i_Send_Trigger;
            rising_edge_trig <= i_Send_Trigger and not prev_trigger;
        end if;
    end process;

    --------------------------------------------------------------------
    -- UART Integrated State Machine
    --------------------------------------------------------------------
    process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            if i_Reset = '1' then
                state         <= IDLE;
                byte_index    <= 0;
                uart_bit_index<= 0;
                uart_clk_count<= 0;
                r_Tx_Serial   <= '1';
                adc_start     <= '0';
            else
                case state is

                    when IDLE =>
                        r_Tx_Serial <= '1';
                        byte_index  <= 0;
                        if rising_edge_trig = '1' then
                            adc_start <= '1';
                            state <= DATA_CAPTURE;
                        end if;

                    when DATA_CAPTURE =>
                        adc_start <= '0';
                        if adc_done = '1' then
                            buffer_34B <= adc_data1 & adc_data2 & encoder_data;
                            state <= LOAD_BYTE;
                        end if;

                    when LOAD_BYTE =>
                        tx_byte <= buffer_34B(271 - byte_index*8 downto 264 - byte_index*8);
                        uart_clk_count <= 0;
                        uart_bit_index <= 0;
                        state <= START_BIT;

                    when START_BIT =>
                        r_Tx_Serial <= '0';
                        if uart_clk_count = c_CLKS_PER_BIT - 1 then
                            uart_clk_count <= 0;
                            state <= DATA_BITS;
                        else
                            uart_clk_count <= uart_clk_count + 1;
                        end if;

                    when DATA_BITS =>
                        r_Tx_Serial <= tx_byte(uart_bit_index);
                        if uart_clk_count = c_CLKS_PER_BIT - 1 then
                            uart_clk_count <= 0;
                            if uart_bit_index < 7 then
                                uart_bit_index <= uart_bit_index + 1;
                            else
                                state <= STOP_BIT1;
                            end if;
                        else
                            uart_clk_count <= uart_clk_count + 1;
                        end if;

                    when STOP_BIT1 =>
                        r_Tx_Serial <= '1';
                        if uart_clk_count = c_CLKS_PER_BIT - 1 then
                            uart_clk_count <= 0;
                            state <= STOP_BIT2;
                        else
                            uart_clk_count <= uart_clk_count + 1;
                        end if;

                    when STOP_BIT2 =>
                        r_Tx_Serial <= '1';
                        if uart_clk_count = c_CLKS_PER_BIT - 1 then
                            uart_clk_count <= 0;
                            state <= NEXT_BYTE;
                        else
                            uart_clk_count <= uart_clk_count + 1;
                        end if;

                    when NEXT_BYTE =>
                        if byte_index < 33 then
                            byte_index <= byte_index + 1;
                            state <= LOAD_BYTE;
                        else
                            state <= IDLE;
                        end if;

                    when others =>
                        state <= IDLE;

                end case;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Outputs
    --------------------------------------------------------------------
    o_Tx_Serial   <= r_Tx_Serial;

    -- Debugging: Export the FSM state
    process(state)
    begin
        case state is
            when IDLE         => o_Debug_State <= "000";
            when DATA_CAPTURE => o_Debug_State <= "001";
            when LOAD_BYTE    => o_Debug_State <= "010";
            when START_BIT    => o_Debug_State <= "011";
            when DATA_BITS    => o_Debug_State <= "100";
            when STOP_BIT1    => o_Debug_State <= "101";
            when STOP_BIT2    => o_Debug_State <= "110";
            when NEXT_BYTE    => o_Debug_State <= "111";
            when others       => o_Debug_State <= "000";
        end case;
    end process;

end Behavioral;
