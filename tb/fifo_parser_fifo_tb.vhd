library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.ALL;

entity fifo_parser_fifo_tb is 
end fifo_parser_fifo_tb;

architecture sim of fifo_parser_fifo_tb is
	constant BUS_SIZE : natural := 32;
	file test_file	: text open read_mode is "/X/intelFPGA_lite/20.1/parser/ecpri_frames_gen2.txt";
	
	signal CLK, RESETn, BUFF_IN_NEXT_FULL, BUFF_OUT_NEXT_EMPTY, READ_EN, WRITE_EN, PVALIDD, PREADYD, PWRITEEN, PREADEN : STD_LOGIC;
	signal DATA_IN, PARSER_IN, PARSER_OUT, DATA_OUT :  STD_LOGIC_VECTOR(BUS_SIZE-1 downto 0);

begin

	uut: entity work.fifo_parser_fifo(rtl)
		generic map(BUS_SIZE=>BUS_SIZE)
		port map(	CLK=>CLK,
						RESETn=>RESETn,
						DATA_IN=>DATA_IN,
						DATA_OUT=>DATA_OUT,
						BUFF_IN_NEXT_FULL=>BUFF_IN_NEXT_FULL,
						BUFF_OUT_NEXT_EMPTY=>BUFF_OUT_NEXT_EMPTY,
						READ_EN=>READ_EN,
						WRITE_EN=>WRITE_EN,
						PARSER_IN=>PARSER_IN,
						PARSER_OUT=>PARSER_OUT,
						PVALIDD=>PVALIDD,
						PREADYD=>PREADYD,
						PREADEN=>PREADEN,
						PWRITEEN=>PWRITEEN);
						
----------------------------------------------------------
--Clock generation
----------------------------------------------------------
clk_proc: process
begin
	CLK <= '0';
	wait for 1 ns;
	CLK <= '1';
	wait for 1 ns;
end process;


----------------------------------------------------------
--Reset stimulus
----------------------------------------------------------
rst_proc: process
begin
	RESETn <= '0';
	wait for 10 ns;
	RESETn <= '1';
	wait;
end process;

----------------------------------------------------------
--Read line from 'test_vector' file and pass it to 'PDADA_IN' variable
----------------------------------------------------------
read_line: process(CLK)
variable test_line : line;
variable line_cnt	 : natural := 0;
variable sulv : bit_vector(31 downto 0);
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			DATA_IN <= (others => '0');
		else
			if not(BUFF_IN_NEXT_FULL) and WRITE_EN then
				if not(endfile(test_file)) then
					line_cnt := line_cnt + 1;
					readline(test_file, test_line);
					hread(test_line, sulv);
					DATA_IN <= To_StdLogicVector(sulv);
				else
					DATA_IN <= DATA_IN;
				end if;
			else
				DATA_IN <= DATA_IN;
			end if;
		end if;
	end if;
end process;

write_en_proc: process(CLK)
variable i : INTEGER := 0;
begin
	if rising_edge(CLK) then
		if RESETn = '0' then
			WRITE_EN <= '0';
			i := 0;
		else
			if i = 9 then
				i := 0;
			else
				i := i + 1;
			end if;
			
			if i >= 1 then
				WRITE_EN <= '1';
			else
				WRITE_EN <= '0';
			end if;
		end if;
	end if;
end process;

read_en_proc: process(CLK)
variable i : INTEGER := 0;
begin
	if rising_edge(CLK) then
		if RESETn = '0' then
			READ_EN <= '0';
			i := 0;
		else
			if i = 9 then
				i := 0;
			else
				i := i + 1;
			end if;
			
			if i >= 1 then
				READ_EN <= '1';
			else
				READ_EN <= '0';
			end if;
		end if;
	end if;
end process;


end sim;