library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.ALL;

entity parser_tb is 
end parser_tb;

architecture sim of parser_tb is

----------------------------------------------------------
-----------------Constant variables-----------------------

constant cBUS_WIDTH 	: NATURAL := 8;
constant cBURST_SIZE : NATURAL := 8;
constant cBUFF_DEPTH : NATURAL := 8;
----------------------------------------------------------

----------------------------------------------------------
---------------Internal testbench signals-----------------
signal ACLK, ARESETn	:  STD_LOGIC;

signal IVALID, IREADY 		: STD_LOGIC;
signal DATA_IN 		 		: STD_LOGIC_VECTOR(cBUS_WIDTH*8-1 downto 0);

signal BUFF_EMPTY, OREADY 	: STD_LOGIC;
signal DATA_OUT 				: STD_LOGIC_VECTOR(cBUS_WIDTH*8-1 downto 0);

signal BIT_CNT_IN, BIT_CNT_OUT : INTEGER;

subtype 	word	is STD_LOGIC_VECTOR(cBUS_WIDTH*8-1 downto 0);
type 		mem	is array(80 downto 0) of word;

signal data_w, data_r : mem := (others=>(others=> '0'));
signal cnt_w, cnt_r : INTEGER range 80 downto 0 := 0;
signal vec_stream : STD_LOGIC_VECTOR(cBUS_WIDTH*8-1 downto 0);


----------------------------------------------------------
--File handling
----------------------------------------------------------
	file test_file	: text open read_mode is "/X/intelFPGA_lite/20.1/parser/an.txt";

begin
----------------------------------------------------------
--Instantiate and port map UUT
----------------------------------------------------------
	uut: entity work.parser_top(structural)
	generic map	(BUS_WIDTH=>cBUS_WIDTH,
					 BURST_SIZE=>cBURST_SIZE,
					 BUFF_DEPTH=>cBUFF_DEPTH)
					
	port map		(ACLK=>ACLK,
					 ARESETn=>ARESETn,
					 DATA_IN=>DATA_IN,
					 IVALID=>IVALID,
					 IREADY=>IREADY,
					 BUFF_EMPTY=>BUFF_EMPTY,
					 DATA_OUT=>DATA_OUT,
					 OREADY=>OREADY,
					 BIT_CNT_IN=>BIT_CNT_IN,
					 BIT_CNT_OUT=>BIT_CNT_OUT);


----------------------------------------------------------
--Clock generation
----------------------------------------------------------
	clk_proc: process
	begin
		ACLK <= '0';
		wait for 1 ns;
		ACLK <= '1';
		wait for 1 ns;
	end process;


----------------------------------------------------------
--Reset stimulus
----------------------------------------------------------
	rst_proc: process
	begin
		ARESETn <= '0';
		wait for 10 ns;
		ARESETn <= '1';
		wait;
	end process;


----------------------------------------------------------
--Read line from 'test_vector' file and pass it to 'row' variable
----------------------------------------------------------
	read_line: process(ACLK)
	variable test_line : line;
	variable line_cnt	 : natural := 0;
	variable sulv : bit_vector(cBUS_WIDTH*8-1 downto 0);
	begin
		if rising_edge(ACLK) then
			if not(ARESETn) then
				vec_stream <= (others => '0');
			elsif not(endfile(test_file)) then
				line_cnt := line_cnt + 1;
				readline(test_file, test_line);
				hread(test_line, sulv);
				vec_stream <= To_StdLogicVector(sulv);
			end if;
		end if;
	end process;
			
end sim;
	