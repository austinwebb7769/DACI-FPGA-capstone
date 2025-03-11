library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Shaft_Encoder is
	Port(
		i_Clk 	 		  : in STD_LOGIC;
		Channel_A 		  : in STD_LOGIC;
		Ready_to_Measure : in STD_LOGIC; --Ready to measure speed
		Channel_B 		  : in STD_LOGIC;
		Data 		 		  : out STD_LOGIC_VECTOR[15 down to 0]; --16 bits since UART receives 8 bits and we need to represent 5000 or less
		Finish_Measure   : out STD_LOGIC; --Speed is finished measuring
		Pulse_1ms		  : out STD_LOGIC; --Pulse for timing 1ms
	)
	
end Shaft_Encoder;

architecture Behavioral of Shaft_Encoder is
	
	constant COUNT_1MS    : integer := 50000; --1ms count
	constant PPR_ENCODER  : integer := 500; --Shaft Encoder Specification
	signal counter_rotate : STD_LOGIC := '0'; --counter to count how many rotations in 1 ms
	signal counter_time 	 : integer range 0 to COUNT_1MS := 0;
	signal RPM 				 : integer := 0;
	signal pulse 	       : STD_LOGIC := '0';
	
begin
	process(i_Clk)
	begin
	if Ready_to_Measure = 1 then
	
		if rising_edge(i_Clk) then
			if counter_time = COUNT_1MS - 1 then
				counter_time <= 0;
				pulse <= '1';
			else
				counter_time <= counter_time + 1;
				pulse <= '0';
			end if;
		end if;	
			
		if rising_edge(Channel_A) then
			counter_rotate <= counter_rotate + 1;
		end if;
		
		if pulse = '1' then
		
			RPM = (counter_rotate / PPR_ENCODER) * (60 / 1ms);
			Data <= std_logic_vector(to_unsigned(RPM, 16));
			counter_rotate <= '0';
			counter_time   <= '0';	
			pulse = '0';
		
		end if;
		
	else
		
		counter_rotate <= '0';
		counter_time   <= '0';
		
	end if;
end process;

--Output Assignments


end Behavioral;		