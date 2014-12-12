LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
use ieee.numeric_std.all;


ENTITY part1 IS
	PORT (CLOCK_50,AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK,AUD_ADCDAT			:IN STD_LOGIC;
			CLOCK2_50																		:IN STD_LOGIC;
			KEY																				:IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			GPIO																				:INOUT STD_LOGIC_VECTOR(25 DOWNTO 0);
			LEDR																				:OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
			LEDG																				:OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			I2C_SDAT																			:INOUT STD_LOGIC;
			I2C_SCLK,AUD_DACDAT,AUD_XCK												:OUT STD_LOGIC;
			SW																					:IN STD_LOGIC_VECTOR(17 DOWNTO 0));
END part1;


ARCHITECTURE rti OF part1 IS
	COMPONENT clock_generator
		PORT(	CLOCK2_50														:IN STD_LOGIC;
		    	reset															:IN STD_LOGIC;
				AUD_XCK														:OUT STD_LOGIC);
	END COMPONENT;

	
	COMPONENT scale_clock 
		port (
    CLOCK3_50 : in  std_logic;
    rst       : in  std_logic;
    clk_2Hz   : out std_logic);
	end COMPONENT;
	
	COMPONENT scale_clock2 
		port (
    CLOCK3_50 : in  std_logic;
    rst       : in  std_logic;
    clk_2Hz   : out std_logic);
	end COMPONENT;

	
	COMPONENT audio_and_video_config
		PORT(	CLOCK_50,reset												:IN STD_LOGIC;
		    	I2C_SDAT														:INOUT STD_LOGIC;
				I2C_SCLK														:OUT STD_LOGIC);
	END COMPONENT;	
	
	COMPONENT fifo_with_division
		GENERIC ( ELEMENT_COUNT : integer := 32);
		PORT( CLOCK_50, reset, read_s			:IN STD_LOGIC;
				data_in							:IN STD_LOGIC_VECTOR(23 DOWNTO 0);
				current_data_out, last_data_out	:OUT STD_LOGIC_VECTOR(23 DOWNTO 0));
	END COMPONENT;

	COMPONENT audio_codec
		PORT(	CLOCK_50,reset,read_s,write_s							:IN STD_LOGIC;
				writedata_left, writedata_right						:IN STD_LOGIC_VECTOR(23 DOWNTO 0);
				AUD_ADCDAT,AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK		:IN STD_LOGIC;
				read_ready, write_ready									:OUT STD_LOGIC;
				readdata_left, readdata_right							:OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
				AUD_DACDAT													:OUT STD_LOGIC);
	END COMPONENT;
	
	
	

	SIGNAL read_ready, write_ready, read_s, write_s				:STD_LOGIC;
	SIGNAL readdata_left, readdata_right, TempData 				:STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL writedata_left, writedata_right							:STD_LOGIC_VECTOR(23 DOWNTO 0);	
	SIGNAL DATA																:STD_LOGIC_VECTOR(23 DOWNTO 0):="000000000000000000000000";	
	SIGNAL reset, out_en, clk_2Hz, clk_400Hz						:STD_LOGIC;
	SIGNAL fftdata															:STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL AudCLK															:STD_LOGIC;
	SIGNAL buffer_left, buffer_right					:STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL divided_left, divided_right					:STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL result_left, result_right					:STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL sum_left, sum_right							:STD_LOGIC_VECTOR(23 DOWNTO 0);
	signal samp: std_logic;
	SIGNAL lights1, lights2, lights3, lights4,lights5				:STD_LOGIC_VECTOR(23 DOWNTO 0);
	signal lights6,	lights7												:STD_LOGIC_VECTOR(25 DOWNTO 0);
	SIGNAL point,points,magnitude : INTEGER;
	SIGNAL count : INTEGER RANGE 0 TO 59;

	

BEGIN
reset <= NOT(KEY(0));
out_en <= NOT(KEY(1));
--samp <= not samp after 250 ms;





Process(TempData,clk_400Hz,readdata_left,magnitude, point, points,lights4,count)

BEGIN

		
IF(RISING_EDGE(clk_400Hz)) THEN

TempData<=result_left;--readdata_left;
point<=abs(to_integer(signed(TempData)));
points<=points+point;
count<=count+1;
lights5<=Std_LOGIC_VECTOR(to_unsigned(count,24));


IF(count=59)THEN

	magnitude<=points/60;--100
	lights4<=Std_LOGIC_VECTOR(to_unsigned(magnitude,24));

	
	lights1<=DATA;
	lights2<=result_left;
	lights3<=divided_left;
	
	points<=0;
		
	--count<=0;
	
ELSE
	
	magnitude<=magnitude;
	lights1<=lights1;
	lights2<=lights2;
	lights3<=lights3;
	lights4<=lights4;	
	
END IF;


ELSE
point<=point;
points<=points;
count<=count;

END IF;
	END PROCESS;
	
			
	
PROCESS (read_ready,KEY(1))
	BEGIN
	
		--LEDR(17 downto 0)<="000000000000000000";
		IF(read_ready = '1' AND NOT(KEY(1)) = '1') THEN
			read_s <= '1';
			DATA <= readdata_left;
			result_left <= sum_left + divided_left - buffer_left;
			result_right <= sum_right + divided_right - buffer_right;
			
			if (SW(0)='1') THEN
			LEDR(17 downto 0)<=lights1(23 downto 6);
			LEDG(7 downto 2)<=lights1(5 downto 0);
			END IF;
			if (SW(1)='1') THEN
			LEDR(17 downto 0)<=lights2(23 downto 6);
			LEDG(7 downto 2)<=lights2(5 downto 0);
			END IF;
			if (SW(2)='1') THEN
			LEDR(17 downto 0)<=lights3(23 downto 6);
			LEDG(7 downto 2)<=lights3(5 downto 0);
			END IF;
			if (SW(3)='1') THEN
			LEDR(15 downto 0)<=lights4(23 downto 8);
			LEDG(7 downto 0)<=lights4(7 downto 0);
			END IF;
			if (SW(4)='1') THEN
			LEDR(15 downto 0)<=lights5(23 downto 8);
			LEDG(7 downto 0)<=lights5(7 downto 0);
			END IF;
			if (SW(5)='1') THEN
			LEDR(17 downto 0)<=lights6(25 downto 8);
			LEDG(7 downto 0)<=lights6(7 downto 0);
			END IF;
			if (SW(6)='1') THEN
			LEDR(17 downto 0)<=lights7(25 downto 8);
			LEDG(7 downto 0)<=lights7(7 downto 0);
			END IF;
		
		
		ELSIF (read_ready = '0' AND NOT(KEY(1)) = '1') THEN
			read_s <= '0';
			--LEDR(17 downto 0)<="000000000000000000";
		END IF;
	END PROCESS;

	PROCESS(CLOCK_50, reset, buffer_left, buffer_right)
		BEGIN
			IF (reset='0') THEN
				sum_left <= "000000000000000000000000";
				sum_right <= "000000000000000000000000";
			ELSIF (RISING_EDGE(CLOCK_50)) THEN
				IF(read_s = '1' AND write_s = '1') THEN
					sum_left <= result_left;
					sum_right <= result_right;
				END IF;
			END IF;			
	END PROCESS;

PROCESS (write_ready,KEY(1),buffer_left,buffer_right)
BEGIN
	IF(write_ready = '1' AND NOT(KEY(1)) = '1') THEN
		write_s <= '1';
		writedata_left <= DATA;
		writedata_right <=DATA;
		--writedata_left <= GPIO(23 DOWNTO 0);
		--writedata_right <= GPIO(23 DOWNTO 0);
	ELSIF (write_ready = '0' AND NOT(KEY(1)) = '1') THEN
		write_s <= '0';
	END IF;
END PROCESS;






--	END PROCESS;


PROCESS(magnitude)

BEGIN
IF(magnitude>=4010) THEN
lights6<="11111111111111111111111111";
ELSIF(magnitude>=3890)THEN
lights6<="11111111111111111111111110";
ELSIF(magnitude>=3770)THEN
lights6<="11111111111111111111111100";
ELSIF(magnitude>=3650)THEN
lights6<="11111111111111111111111000";
ELSIF(magnitude>=3530)THEN
lights6<="11111111111111111111110000";
ELSIF(magnitude>=3410)THEN
lights6<="11111111111111111111100000";
ELSIF(magnitude>=3290)THEN
lights6<="11111111111111111111000000";
ELSIF(magnitude>=3170)THEN
lights6<="11111111111111111110000000";
ELSIF(magnitude>=3050)THEN
lights6<="11111111111111111100000000";
ELSIF(magnitude>=2930)THEN
lights6<="11111111111111111000000000";
ELSIF(magnitude>=2810)THEN
lights6<="11111111111111110000000000";
ELSIF(magnitude>=2690)THEN
lights6<="11111111111111100000000000";
ELSIF(magnitude>=2570)THEN
lights6<="11111111111111000000000000";
ELSIF(magnitude>=2450)THEN
lights6<="11111111111110000000000000";
ELSIF(magnitude>=2330)THEN
lights6<="11111111111100000000000000";
ELSIF(magnitude>=2210)THEN
lights6<="11111111111000000000000000";
ELSIF(magnitude>=2090)THEN
lights6<="11111111110000000000000000";
ELSIF(magnitude>=1970)THEN
lights6<="11111111100000000000000000";
ELSIF(magnitude>=1850)THEN
lights6<="11111111000000000000000000";
ELSIF(magnitude>=1730)THEN
lights6<="11111110000000000000000000";
ELSIF(magnitude>=1610)THEN
lights6<="11111100000000000000000000";
ELSIF(magnitude>=1490)THEN
lights6<="11111000000000000000000000";
ELSIF(magnitude>=1370)THEN
lights6<="11110000000000000000000000";
ELSIF(magnitude>=1250)THEN
lights6<="11100000000000000000000000";
ELSIF(magnitude>=1130)THEN
lights6<="11000000000000000000000000";
ELSIF(magnitude>=1110)THEN
lights6<="10000000000000000000000000";
ELSIF(magnitude>=990)THEN
lights6<="00000000000000000000000000";
END IF;
END PROCESS;

PROCESS(magnitude)

BEGIN
IF(magnitude>=4010) THEN
lights7<="11111111111111111111111111";
ELSIF(magnitude>=3890)THEN
lights7<="11111111111111111111111111";
ELSIF(magnitude>=3770)THEN
lights7<="01111111111111111111111110";
ELSIF(magnitude>=3650)THEN
lights7<="01111111111111111111111110";
ELSIF(magnitude>=3530)THEN
lights7<="00111111111111111111111100";
ELSIF(magnitude>=3410)THEN
lights7<="00111111111111111111111100";
ELSIF(magnitude>=3290)THEN
lights7<="00011111111111111111111000";
ELSIF(magnitude>=3170)THEN
lights7<="00011111111111111111111000";
ELSIF(magnitude>=3050)THEN
lights7<="00001111111111111111110000";
ELSIF(magnitude>=2930)THEN
lights7<="00001111111111111111110000";
ELSIF(magnitude>=2810)THEN
lights7<="00000111111111111111100000";
ELSIF(magnitude>=2690)THEN
lights7<="00000111111111111111100000";
ELSIF(magnitude>=2570)THEN
lights7<="00000011111111111111000000";
ELSIF(magnitude>=2450)THEN
lights7<="00000011111111111111000000";
ELSIF(magnitude>=2330)THEN
lights7<="00000001111111111110000000";
ELSIF(magnitude>=2210)THEN
lights7<="00000001111111111110000000";
ELSIF(magnitude>=2090)THEN
lights7<="00000000111111111100000000";
ELSIF(magnitude>=1970)THEN
lights7<="00000000111111111100000000";
ELSIF(magnitude>=1850)THEN
lights7<="00000000011111111000000000";
ELSIF(magnitude>=1730)THEN
lights7<="00000000011111111000000000";
ELSIF(magnitude>=1610)THEN
lights7<="00000000001111110000000000";
ELSIF(magnitude>=1490)THEN
lights7<="00000000001111110000000000";
ELSIF(magnitude>=1370)THEN
lights7<="00000000000111100000000000";
ELSIF(magnitude>=1250)THEN
lights7<="00000000000111100000000000";
ELSIF(magnitude>=1130)THEN
lights7<="00000000000011000000000000";
ELSIF(magnitude>=1110)THEN
lights7<="00000000000011000000000000";
ELSIF(magnitude>=990)THEN
lights7<="00000000000000000000000000";
END IF;
END PROCESS;


left_buffer: fifo_with_division
				GENERIC MAP ( ELEMENT_COUNT => 32)
				PORT MAP (CLOCK_50, reset, read_s, readdata_left, divided_left, buffer_left);
right_buffer: fifo_with_division
				GENERIC MAP ( ELEMENT_COUNT => 32)
				PORT MAP (CLOCK_50, reset, read_s, readdata_right, divided_right, buffer_right);

	--myfft: fft64pt_seq PORT MAP(reset, AudCLK, DATA(15 downto 0), CLOCK_50, fftdata);
	my_clock_gen: clock_generator PORT MAP (CLOCK2_50, reset, AUD_XCK);
	cfg: audio_and_video_config PORT MAP (CLOCK_50, reset, I2C_SDAT, I2C_SCLK);
	codec: audio_codec PORT MAP(CLOCK_50,reset,read_s,write_s,writedata_left, writedata_right,AUD_ADCDAT,AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK,read_ready, write_ready,readdata_left, readdata_right,AUD_DACDAT);
	sampleme: scale_clock PORT MAP(CLOCK_50,reset,clk_2Hz);
	samplemo: scale_clock2 PORT MAP(CLOCK_50,reset,clk_400Hz);
	
	
END rti;









-------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity scale_clock2 is
  port (
    CLOCK3_50 : in  std_logic;
    rst       : in  std_logic;
    clk_2Hz   : out std_logic);
end scale_clock2;

architecture Behavioral of scale_clock2 is

  signal prescaler : unsigned(23 downto 0);
  signal clk_2Hz_i : std_logic;
begin

  gen_clk : process (CLOCK3_50, rst)
  begin  -- process gen_clk
    if rst = '1' then
      clk_2Hz_i   <= '0';
      prescaler   <= (others => '0');  --(clock_speed/desired_clock_speed)/2
    elsif rising_edge(CLOCK3_50) then   -- rising clock edge
      if prescaler = X"7A12" then     -- 800hz 200 samples ever .25 seconds
        prescaler   <= (others => '0');
        clk_2Hz_i   <= not clk_2Hz_i;
      else
        prescaler <= prescaler + "1";
      end if;
    end if;
  end process gen_clk;

clk_2Hz <= clk_2Hz_i;

end Behavioral;
-------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity scale_clock is
  port (
    CLOCK3_50 : in  std_logic;
    rst       : in  std_logic;
    clk_2Hz   : out std_logic);
end scale_clock;

architecture Behavioral of scale_clock is

  signal prescaler : unsigned(23 downto 0);
  signal clk_2Hz_i : std_logic;
begin

  gen_clk : process (CLOCK3_50, rst)
  begin  -- process gen_clk
    if rst = '1' then
      clk_2Hz_i   <= '0';
      prescaler   <= (others => '0');  --(clock_speed/desired_clock_speed)/2
    elsif rising_edge(CLOCK3_50) then   -- rising clock edge
      if prescaler = X"5F5E10" then     -- 12 500 000 in hex --5F5E10 -> .25 -- BEBC20 ->.5
        prescaler   <= (others => '0');
        clk_2Hz_i   <= not clk_2Hz_i;
      else
        prescaler <= prescaler + "1";
      end if;
    end if;
  end process gen_clk;

clk_2Hz <= clk_2Hz_i;

end Behavioral;

--------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

ENTITY fifo_with_division IS
	GENERIC ( ELEMENT_COUNT : integer := 32);
	PORT (	CLOCK_50, reset, read_s				:IN STD_LOGIC;
			data_in								:IN STD_LOGIC_VECTOR(23 DOWNTO 0);
			current_data_out, last_data_out		:OUT STD_LOGIC_VECTOR(23 DOWNTO 0));
END fifo_with_division;


ARCHITECTURE Behavior OF fifo_with_division IS
	TYPE buffer_temp IS ARRAY(0 TO ELEMENT_COUNT-1) OF STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL buffer_s 		:buffer_temp;
	SIGNAL input_divided	:STD_LOGIC_VECTOR(23 DOWNTO 0);
	
BEGIN
	-- This is the 24-bit input divided by 32. The 5 left-most bits are sign extension bits.
	input_divided <= ((data_in(23))&(data_in(23))&(data_in(23))&(data_in(23))&(data_in(23)))&(data_in(23 DOWNTO 5));
	
	-- Creation of successive fifo shift registers
	G2: FOR index IN 0 TO ELEMENT_COUNT-1 GENERATE
	
		PROCESS(CLOCK_50, reset, read_s, buffer_s, input_divided)
		BEGIN
			IF (reset='0') THEN
				buffer_s(index) <= "000000000000000000000000";
			ELSIF (RISING_EDGE(CLOCK_50)) THEN
				IF(read_s = '1') THEN
					IF(index = 0) THEN
						buffer_s(index) <= input_divided;
					ELSE
						buffer_s(index) <= buffer_s(index-1);
					END IF;
				END IF;
			END IF;	
		END PROCESS;

	END GENERATE;
	
	current_data_out <= input_divided;
	last_data_out <= buffer_s(ELEMENT_COUNT-1);
	
END Behavior;
