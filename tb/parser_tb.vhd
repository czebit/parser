library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.ALL;

entity parser_tb is 
end parser_tb;

architecture sim of parser_tb is
----------------------------------------------------------
--Unit under test declaration
----------------------------------------------------------
	component parser_top is
		generic(
			BUS_WIDTH : natural
		);
		
		port(
		CLK		: in STD_LOGIC;
		RESETn	: in STD_LOGIC;
		INPUT		: in STD_LOGIC_VECTOR(BUS_WIDTH*8-1 downto 0)
		);
	end component;


----------------------------------------------------------
--Constant variables
----------------------------------------------------------
	constant cBUS_WIDTH : natural := 8;


----------------------------------------------------------
--Internal testbench signals
----------------------------------------------------------
	signal CLK			: STD_LOGIC;
	signal RESETn		: STD_LOGIC;
	signal INPUT		: STD_LOGIC_VECTOR(cBUS_WIDTH*8-1 downto 0);
	signal vec_stream	: STD_LOGIC_VECTOR(cBUS_WIDTH*8-1 downto 0);


----------------------------------------------------------
--File handling
----------------------------------------------------------
	file test_vector 	: text open read_mode is "file.txt";


begin
----------------------------------------------------------
--Instantiate and port map UUT
----------------------------------------------------------
	uut: parser_top
	generic map	(BUS_WIDTH=>cBuS_WIDTH)
	port map		(CLK=>CLK,
					RESETn=>RESETn,
					INPUT=>INPUT);


----------------------------------------------------------
--Clock generation
----------------------------------------------------------
	clk_proc: process
	begin
		CLK <= '0';
		wait for 1ns;
		CLK <= '1';
		wait for 1ns;
	end process;


----------------------------------------------------------
--Reset stimulus
----------------------------------------------------------
	rst_proc: process
	begin
		RESETn <= '0';
		wait for 10ns;
		RESETn <= '1';
		wait;
	end process;


----------------------------------------------------------
--Read line from 'test_vector' file and pass it to 'row' variable
----------------------------------------------------------
	read_line: process(CLK)
	variable row		: line;
	variable row_cnt	: natural := 0;
	begin
		if rising_edge(CLK) then
			if RESETn = '0' then
				vec_stream <= (others => '0');
			elsif not(endfile(test_vector)) then
				row_cnt := row_cnt + 1;
				readline(test_vector, row);
			end if;
		end if;
	end process;
			
end sim;
	