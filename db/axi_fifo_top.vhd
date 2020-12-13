library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity axi_fifo_top is

generic(	BUS_WIDTH 	: natural := 32;
			BURST_SIZE 	: natural := 64;
			BUFF_DEPTH	: natural := 16);


	port(	ACLK			: in STD_LOGIC;
			ARESETn		: in STD_LOGIC;
			DATA_IN 		: in STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0);
			IVALID 		: in STD_LOGIC;
			IREADY		: out STD_LOGIC;
			BUFF_EMPTY	: out STD_LOGIC;
			DATA_OUT 	: out STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0);
			OREADY 		: in STD_LOGIC;
			BIT_CNT_IN	: out INTEGER range BURST_SIZE downto 0;
			BIT_CNT_OUT : out INTEGER range BURST_SIZE downto 0);
			
end axi_fifo_top;

architecture structural of axi_fifo_top is

signal last_i, fifo_next_full_i, inv_fifo_next_full_i, axi_out_valid_i : STD_LOGIC;
signal data_i : STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0);

begin
	
	inv_fifo_next_full_i <= not(fifo_next_full_i);

	AXI: entity work.axi_top(structural)
			generic map(AXI_BUS_WIDTH=>BUS_WIDTH,
							AXI_BURST_SIZE=>BURST_SIZE)
							
			port map (	AXI_ACLK=>ACLK,
							AXI_ARESETn=>ARESETn,
							AXI_DATA_IN=>DATA_IN,
							AXI_IVALID=>IVALID,
							AXI_IREADY=>IREADY,
							AXI_OVALID=>axi_out_valid_i,
							AXI_DATA_OUT=>data_i,
							AXI_OREADY=>inv_fifo_next_full_i,
							AXI_BIT_CNT_IN=>BIT_CNT_IN,
							AXI_BIT_CNT_OUT=>BIT_CNT_OUT);

	FIFO1: entity work.fifo(rtl)
				generic map(FIFO_BUS_WIDTH=>BUS_WIDTH,
								FIFO_BUFF_DEPTH=>BUFF_DEPTH)

				port map(	FIFO_RESETn=>ARESETn,
								FIFO_CLK=>ACLK,
								FIFO_DATA_IN=>data_i,
								FIFO_DATA_OUT=>DATA_OUT,
								FIFO_WRITE_EN=>axi_out_valid_i,
								FIFO_READ_EN=>OREADY,
								FIFO_NEXT_EMPTY=>BUFF_EMPTY,
								FIFO_NEXT_FULL=>fifo_next_full_i);
				
end structural;
