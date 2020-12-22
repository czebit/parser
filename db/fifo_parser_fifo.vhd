library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.ALL;

entity fifo_parser_fifo is
	generic(	BUS_SIZE : NATURAL := 32);
	
	port(		CLK, RESETn : in STD_LOGIC;
				DATA_IN 		: in STD_LOGIC_VECTOR(BUS_SIZE-1 downto 0);
				DATA_OUT 	: out STD_LOGIC_VECTOR(BUS_SIZE-1 downto 0);
				PARSER_IN, PARSER_OUT : out STD_LOGIC_VECTOR(BUS_SIZE-1 downto 0);
				BUFF_IN_NEXT_FULL, BUFF_OUT_NEXT_EMPTY, PVALIDD, PREADYD, PREADEN, PWRITEEN : out STD_LOGIC;
				READ_EN, WRITE_EN : in STD_LOGIC);
			
end fifo_parser_fifo;

architecture rtl of fifo_parser_fifo is

	signal fifo_data_out_i, parser_data_out_i : STD_LOGIC_VECTOR(BUS_SIZE-1 downto 0);
	signal fifo_out_nfull_i, fifo_in_nempty_i, pready_i, pvalid_i, pwrite_en_i, pread_en_i : STD_LOGIC;
	
begin
	PREADEN <= pread_en_i;
	PWRITEEN <= pwrite_en_i;
	PVALIDD <= pvalid_i;
	PREADYD <= pready_i;
	PARSER_IN <= fifo_data_out_i;
	PARSER_OUT <= parser_data_out_i;
	pwrite_en_i <= not(fifo_in_nempty_i);
	pread_en_i <= not(fifo_out_nfull_i);
	
	fifo_in: entity work.fifo(rtl)
		generic map(FIFO_BUS_WIDTH=>BUS_SIZE,
						FIFO_BUFF_DEPTH=>16)
		port map(	FIFO_CLK=>CLK,
						FIFO_RESETn=>RESETn,
						FIFO_DATA_IN=>DATA_IN,
						FIFO_DATA_OUT=>fifo_data_out_i,
						FIFO_READ_EN=>pready_i,
						FIFO_WRITE_EN=>WRITE_EN,
						FIFO_EMPTY=>open,
						FIFO_NEXT_EMPTY=>fifo_in_nempty_i,
						FIFO_NEXT_FULL=>BUFF_IN_NEXT_FULL);
		
	parser1: entity work.parser(rtl)
		port map(	RESETn=>RESETn,
		            CLK=>CLK,
		            PDATA_IN=>fifo_data_out_i,
		            PDATA_OUT=>parser_data_out_i,
		            PDATA_H_OUT=>open,
		            PREAD_EN=>pread_en_i,
		            PWRITE_EN=>pwrite_en_i,
		            PREADY=>pready_i,
		            PVALID=>pvalid_i,
		            PLAST=>open);
		
	fifo_out: entity work.fifo(rtl)
		generic map(FIFO_BUS_WIDTH=>BUS_SIZE,
						FIFO_BUFF_DEPTH=>16)
		port map(	FIFO_CLK=>CLK,
						FIFO_RESETn=>RESETn,
						FIFO_DATA_IN=>parser_data_out_i,
						FIFO_DATA_OUT=>DATA_OUT,
						FIFO_READ_EN=>READ_EN,
						FIFO_WRITE_EN=>pvalid_i,
						FIFO_EMPTY=>open,
						FIFO_NEXT_EMPTY=>BUFF_OUT_NEXT_EMPTY,
						FIFO_NEXT_FULL=>fifo_out_nfull_i);
						--FIFO_NEXT_FULL=>open);
		
end rtl;