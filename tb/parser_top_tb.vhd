library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.ALL;

entity parser_top_tb is 
end parser_top_tb;

architecture sim of parser_top_tb is

----------------------------------------------------------
-----------------Constant variables-----------------------

constant cBUS_WIDTH 			: NATURAL := 32;
constant cBUFF_DEPTH 		: NATURAL := 16;
constant cAXI_TUSER_WIDTH 	: NATURAL := 32;
----------------------------------------------------------

----------------------------------------------------------
---------------Internal testbench signals-----------------
signal CLK, RESETn	:  STD_LOGIC;

signal TDATA_IN, TDATA_OUT : STD_LOGIC_VECTOR(cBUS_WIDTH-1 downto 0);
signal TVALID_IN, TVALID_OUT, TREADY_IN, TREADY_OUT, TLAST_IN, TLAST_OUT : STD_LOGIC;

signal BUFF_EMPTY, BUFF_OVERFLOW : STD_LOGIC;
signal BIT_CNT_OUT, BIT_CNT_IN : INTEGER;

signal TKEEP_IN, TKEEP_OUT : STD_LOGIC_VECTOR(cBUS_WIDTH/8 -1 downto 0);
signal TUSER_OUT : STD_LOGIC_VECTOR(cAXI_TUSER_WIDTH -1 downto 0);

signal AXI_M_BIT_CNT : INTEGER;
signal AXI_S_BIT_CNT : INTEGER;

signal AXI_M_TDATA, AXI_M_DATA_IN : STD_LOGIC_VECTOR(cBUS_WIDTH-1 downto 0);
signal AXI_S_TDATA, AXI_S_DATA_OUT : STD_LOGIC_VECTOR(cBUS_WIDTH-1 downto 0);

signal AXI_M_TVALID, AXI_M_IVALID, AXI_M_LAST_IN, AXI_M_TLAST, AXI_M_TREADY, AXI_M_IREADY : STD_LOGIC;
signal AXI_S_TVALID, AXI_S_OVALID, AXI_S_LAST_OUT, AXI_S_TLAST, AXI_S_TREADY, AXI_S_OREADY : STD_LOGIC;

signal AXI_M_KEEP_IN, AXI_M_TKEEP : STD_LOGIC_VECTOR(cBUS_WIDTH/8 -1 downto 0);
signal AXI_S_KEEP_OUT, AXI_S_TKEEP : STD_LOGIC_VECTOR(cBUS_WIDTH/8 -1 downto 0);

signal AXI_M_TUSER_IN, AXI_M_TUSER : STD_LOGIC_VECTOR(cAXI_TUSER_WIDTH -1 downto 0);
signal AXI_S_TUSER_OUT, AXI_S_TUSER : STD_LOGIC_VECTOR(cAXI_TUSER_WIDTH -1 downto 0);

----------------------------------------------------------
--File handling
----------------------------------------------------------
	file test_file	: text open read_mode is "/X/intelFPGA_lite/20.1/parser/ecpri_frames_3.txt";

begin
----------------------------------------------------------
--Instantiate and port map UUT
----------------------------------------------------------
	uut: entity work.parser_top(structural)
		generic map(BUS_WIDTH=>cBUS_WIDTH,
						BUFF_DEPTH=>cBUFF_DEPTH)
					
		port map	(	CLK				=>	CLK,
						RESETn			=>	RESETn,
						TDATA_IN			=>	TDATA_IN,
						TVALID_IN		=>	TVALID_IN,
						TREADY_IN		=>	TREADY_IN,
						TLAST_IN			=>	TLAST_IN,
						TDATA_OUT		=>	TDATA_OUT,
						TVALID_OUT		=>	TVALID_OUT,
						TREADY_OUT		=>	TREADY_OUT,
						TLAST_OUT		=>	TLAST_OUT,
						BUFF_EMPTY		=>	BUFF_EMPTY,
						BUFF_OVERFLOW	=>	BUFF_OVERFLOW,
						BIT_CNT_IN		=>	BIT_CNT_IN,
						BIT_CNT_OUT		=>	BIT_CNT_OUT,
						TKEEP_IN			=>	TKEEP_IN,
						TKEEP_OUT		=>	TKEEP_OUT,
						TUSER_OUT		=>	TUSER_OUT
						);
						
	AXI_ST_MASTER1: entity work.axi_st_master(rtl)
		generic map(AXI_M_BUS_WIDTH	=>	cBUS_WIDTH,
						AXI_M_TUSER_WIDTH	=>	cAXI_TUSER_WIDTH)
		port map(	AXI_M_ARESETn		=>	RESETn,
						AXI_M_ACLK			=>	CLK,
						AXI_M_IVALID		=>	AXI_M_IVALID,
						AXI_M_IREADY		=>	AXI_M_IREADY,
						AXI_M_DATA_IN		=>	AXI_M_DATA_IN,
						AXI_M_TREADY		=>	AXI_M_TREADY,
						AXI_M_TVALID		=>	AXI_M_TVALID,
						AXI_M_TDATA			=>	AXI_M_TDATA,
						AXI_M_TLAST			=>	AXI_M_TLAST,
						AXI_M_LAST_IN		=>	AXI_M_LAST_IN,
						AXI_M_BIT_CNT		=>	AXI_M_BIT_CNT,
						AXI_M_TKEEP			=>	AXI_M_TKEEP,
						AXI_M_KEEP_IN		=>	AXI_M_KEEP_IN,
						AXI_M_TUSER_IN		=>	AXI_M_TUSER_IN,
						AXI_M_TUSER			=>	AXI_M_TUSER
						);
						
	AXI_ST_SLAVE1: entity work.axi_st_slave(rtl)
		generic map(AXI_S_BUS_WIDTH	=>	cBUS_WIDTH,
						AXI_S_TUSER_WIDTH	=>	cAXI_TUSER_WIDTH)					
		port map(	AXI_S_ARESETn		=>	RESETn,
						AXI_S_ACLK			=>	CLK,
						AXI_S_TDATA			=>	AXI_S_TDATA,
						AXI_S_TVALID		=>	AXI_S_TVALID,
						AXI_S_TLAST			=>	AXI_S_TLAST,
						AXI_S_LAST_OUT		=>	AXI_S_LAST_OUT,
						AXI_S_TREADY		=>	AXI_S_TREADY,
						AXI_S_OVALID		=>	AXI_S_OVALID,
						AXI_S_DATA_OUT		=>	AXI_S_DATA_OUT,
						AXI_S_OREADY		=>	AXI_S_OREADY,
						AXI_S_BIT_CNT		=>	AXI_S_BIT_CNT,
						AXI_S_KEEP_OUT		=>	AXI_S_KEEP_OUT,
						AXI_S_TKEEP			=>	AXI_S_TKEEP,
						AXI_S_TUSER			=>	AXI_S_TUSER,
						AXI_S_TUSER_OUT	=>	AXI_S_TUSER_OUT
						);

				AXI_M_IVALID 	: in STD_LOGIC;
				AXI_M_TUSER_IN	: in STD_LOGIC_VECTOR(AXI_M_TUSER_WIDTH - 1 downto 0);
				AXI_M_KEEP_IN	: in STD_LOGIC_VECTOR(AXI_M_BUS_WIDTH/8 - 1 downto 0);
				AXI_M_LAST_IN	: in STD_LOGIC;
				AXI_M_DATA_IN	: in STD_LOGIC_VECTOR(AXI_M_BUS_WIDTH-1 downto 0);
				AXI_M_TREADY	: in STD_LOGIC;
				
				
	AXI_S_TDATA			<= TDATA_IN;
	AXI_S_TVALID		<= TVALID_IN;
	AXI_S_TLAST			<=	TLAST_IN;
	AXI_S_LAST_OUT		
	AXI_S_TREADY		<=	TREADY_IN;
	AXI_S_OVALID		
	AXI_S_DATA_OUT		
	AXI_S_OREADY		
	AXI_S_BIT_CNT		
	AXI_S_KEEP_OUT		
	AXI_S_TKEEP			
	AXI_S_TUSER			
	AXI_S_TUSER_OUT	
	
	AXI_M_IVALID	<= 	
	AXI_M_IREADY
	AXI_M_DATA_IN	<= 
	AXI_M_TREADY	<= 
	AXI_M_TVALID	<=
	AXI_M_TDATA		<=
	AXI_M_TLAST		<=
	AXI_M_LAST_IN	<=
	AXI_M_BIT_CNT	<=
	AXI_M_TKEEP		<=
	AXI_M_KEEP_IN	<=
	AXI_M_TUSER_IN	<=
	AXI_M_TUSER		<=
	AXI_M_IVALID <= '1';
	AXI_S_OREADY <= '1';
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
--Read line from 'test_vector' file and pass it to 'row' variable
----------------------------------------------------------
read_line: process(CLK)
variable test_line : line;
variable line_cnt	 : natural := 0;
variable sulv : bit_vector(31 downto 0);
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			AXI_M_DATA_IN <= (others => '0');
		else
			if AXI_M_IREADY and AXI_M_IVALID then
				if not(endfile(test_file)) then
					line_cnt := line_cnt + 1;
					readline(test_file, test_line);
					hread(test_line, sulv);
					AXI_M_DATA_IN <= To_StdLogicVector(sulv);
				else
					AXI_M_DATA_IN <= AXI_M_DATA_IN;
				end if;
			else
				AXI_M_DATA_IN <= AXI_M_DATA_IN;
			end if;
		end if;
	end if;
end process;
			
end sim;
	