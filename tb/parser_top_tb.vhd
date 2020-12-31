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

signal AXI_M_TDATA, AXI_M_IDATA : STD_LOGIC_VECTOR(cBUS_WIDTH-1 downto 0);
signal AXI_M_TVALID, AXI_M_IVALID, AXI_M_ILAST, AXI_M_TLAST, AXI_M_TREADY, AXI_M_IREADY : STD_LOGIC;
signal AXI_M_IKEEP, AXI_M_TKEEP : STD_LOGIC_VECTOR(cBUS_WIDTH/8 -1 downto 0);
signal AXI_M_IUSER : STD_LOGIC_VECTOR(cAXI_TUSER_WIDTH -1 downto 0);

signal TDATA_S, TDATA_M : STD_LOGIC_VECTOR(cBUS_WIDTH-1 downto 0);
signal TVALID_S, TVALID_M, TREADY_S, TREADY_M, TLAST_S, TLAST_M : STD_LOGIC;

signal BUFF_EMPTY, BUFF_OVERFLOW : STD_LOGIC;
signal BIT_CNT_M, BIT_CNT_S : INTEGER;

signal TKEEP_S, TKEEP_M : STD_LOGIC_VECTOR(cBUS_WIDTH/8 -1 downto 0);
signal TUSER_M : STD_LOGIC_VECTOR(cAXI_TUSER_WIDTH -1 downto 0);

signal AXI_S_TDATA, AXI_S_ODATA : STD_LOGIC_VECTOR(cBUS_WIDTH-1 downto 0);
signal AXI_S_TVALID, AXI_S_OVALID, AXI_S_OLAST, AXI_S_TLAST, AXI_S_TREADY, AXI_S_OREADY : STD_LOGIC;
signal AXI_S_OKEEP, AXI_S_TKEEP : STD_LOGIC_VECTOR(cBUS_WIDTH/8 -1 downto 0);
signal AXI_S_OUSER, AXI_S_TUSER : STD_LOGIC_VECTOR(cAXI_TUSER_WIDTH -1 downto 0);

signal AXI_M_CNT : INTEGER;
signal AXI_S_CNT : INTEGER;


----------------------------------------------------------
--File handling
----------------------------------------------------------
	file test_file		: text open read_mode is "/X/intelFPGA_lite/20.1/parser/ecpri_frames_gen3.txt";
	file payload_file	: text open write_mode is "/X/intelFPGA_lite/20.1/parser/tb_output/payload_output.txt";
	file header_file	: text open write_mode is "/X/intelFPGA_lite/20.1/parser/tb_output/header_output.txt";
	file keep_file		: text open write_mode is "/X/intelFPGA_lite/20.1/parser/tb_output/keep_output.txt";
	
begin
----------------------------------------------------------
--Instantiate and port map UUT
----------------------------------------------------------
	uut: entity work.parser_top(structural)
		generic map(BUS_WIDTH=>cBUS_WIDTH,
						BUFF_DEPTH=>cBUFF_DEPTH)
					
		port map	(	CLK				=>	CLK,
						RESETn			=>	RESETn,
						TDATA_S			=>	TDATA_S,
						TVALID_S			=>	TVALID_S,
						TREADY_S			=>	TREADY_S,
						TLAST_S			=>	TLAST_S,
						TDATA_M			=>	TDATA_M,
						TVALID_M			=>	TVALID_M,
						TREADY_M			=>	TREADY_M,
						TLAST_M			=>	TLAST_M,
						BUFF_EMPTY		=>	BUFF_EMPTY,
						BUFF_OVERFLOW	=>	BUFF_OVERFLOW,
						BIT_CNT_S		=>	BIT_CNT_S,
						BIT_CNT_M		=>	BIT_CNT_M,
						TKEEP_S			=>	TKEEP_S,
						TKEEP_M			=>	TKEEP_M,
						TUSER_M			=>	TUSER_M
						);
						
	AXI_ST_MASTER1: entity work.axi_st_master(rtl)
		generic map(AXI_M_BUS_WIDTH	=>	cBUS_WIDTH,
						AXI_M_TUSER_WIDTH	=>	cAXI_TUSER_WIDTH)
		port map(	AXI_M_ARESETn		=>	RESETn,
						AXI_M_ACLK			=>	CLK,
						AXI_M_IVALID		=>	AXI_M_IVALID,
						AXI_M_IREADY		=>	AXI_M_IREADY,
						AXI_M_IDATA			=>	AXI_M_IDATA,
						AXI_M_TREADY		=>	AXI_M_TREADY,
						AXI_M_TVALID		=>	AXI_M_TVALID,
						AXI_M_TDATA			=>	AXI_M_TDATA,
						AXI_M_TLAST			=>	AXI_M_TLAST,
						AXI_M_ILAST			=>	AXI_M_ILAST,
						AXI_M_CNT			=>	AXI_M_CNT,
						AXI_M_TKEEP			=>	AXI_M_TKEEP,
						AXI_M_IKEEP			=>	AXI_M_IKEEP,
						AXI_M_IUSER		=>	AXI_M_IUSER,
						AXI_M_TUSER			=>	open
						);
						
	AXI_ST_SLAVE1: entity work.axi_st_slave(rtl)
		generic map(AXI_S_BUS_WIDTH	=>	cBUS_WIDTH,
						AXI_S_TUSER_WIDTH	=>	cAXI_TUSER_WIDTH)					
		port map(	AXI_S_ARESETn		=>	RESETn,
						AXI_S_ACLK			=>	CLK,
						AXI_S_TDATA			=>	AXI_S_TDATA,
						AXI_S_TVALID		=>	AXI_S_TVALID,
						AXI_S_TLAST			=>	AXI_S_TLAST,
						AXI_S_OLAST			=>	AXI_S_OLAST,
						AXI_S_TREADY		=>	AXI_S_TREADY,
						AXI_S_OVALID		=>	AXI_S_OVALID,
						AXI_S_ODATA			=>	AXI_S_ODATA,
						AXI_S_OREADY		=>	AXI_S_OREADY,
						AXI_S_CNT			=>	AXI_S_CNT,
						AXI_S_OKEEP			=>	AXI_S_OKEEP,
						AXI_S_TKEEP			=>	AXI_S_TKEEP,
						AXI_S_TUSER			=>	AXI_S_TUSER,
						AXI_S_OUSER			=>	AXI_S_OUSER
						);
				
	AXI_M_TREADY	<= TREADY_S;
	TVALID_S			<= AXI_M_TVALID;
	TDATA_S			<= AXI_M_TDATA;
	TLAST_S			<= AXI_M_TLAST;
	TKEEP_S			<= AXI_M_TKEEP;
	
	AXI_M_ILAST	<= '0';
	AXI_M_IKEEP	<= (others=>'1');
	AXI_M_IUSER	<= (others=>'0');
	
	AXI_S_TDATA			<= TDATA_M;
	AXI_S_TVALID		<= TVALID_M;
	AXI_S_TLAST			<=	TLAST_M;
	TREADY_M 			<= AXI_S_TREADY;
	AXI_S_TKEEP			<= TKEEP_M;
	AXI_S_TUSER			<= TUSER_M;

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
--Read line from file with test vectors and pass it to component input
----------------------------------------------------------
read_test_pcap: process(CLK)
variable rline : line;
variable sulv : bit_vector(31 downto 0);
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			AXI_M_IDATA <= (others => '0');
		else
			if AXI_M_IREADY and AXI_M_IVALID then
				if not(endfile(test_file)) then
					readline(test_file, rline);
					hread(rline, sulv);
					AXI_M_IDATA <= To_StdLogicVector(sulv);
				else
					AXI_M_IDATA <= AXI_M_IDATA;
				end if;
			else
				AXI_M_IDATA <= AXI_M_IDATA;
			end if;
		end if;
	end if;
end process;

----------------------------------------------------------
--Write lines from outputs to files 
----------------------------------------------------------
write_payload_file: process(CLK)
variable p_line : line;
variable h_line : line;
variable k_line : line;
begin
	if rising_edge(CLK) then
		if AXI_S_OVALID then
			hwrite(p_line, To_BitVector(AXI_S_ODATA));
			hwrite(h_line, To_BitVector(AXI_S_OUSER));
			hwrite(k_line, To_BitVector(AXI_S_OKEEP));
			writeline(payload_file, p_line);
			writeline(keep_file, 	k_line);
			writeline(header_file, 	h_line);
		end if;
	end if;
end process;

----------------------------------------------------------
--Backpreasure stimulus
----------------------------------------------------------	

read_proc: process(CLK)
variable i : INTEGER := 0;
begin
	if rising_edge(CLK) then
		if RESETn = '0' then
			AXI_S_OREADY <= '0';
			i := 0;
		else
			if i = 27 then
				i := 0;
			else
				i := i + 1;
			end if;
			if i >= 4 then
				AXI_S_OREADY <= '1';
			else
				AXI_S_OREADY <= '0';
			end if;
		end if;
	end if;
end process;

--AXI_S_OREADY <= '1';

----------------------------------------------------------
--write stimulus
----------------------------------------------------------

write_en_proc: process(CLK)
variable i : INTEGER := 0;
begin
	if rising_edge(CLK) then
		if RESETn = '0' then
			AXI_M_IVALID <= '0';
			i := 0;
		else
			if i = 20 then
				i := 0;
			else
				i := i + 1;
			end if;
			
			if i >= 3 then
				AXI_M_IVALID <= '1';
			else
				AXI_M_IVALID <= '0';
			end if;
		end if;
	end if;
end process;


--	AXI_M_IVALID	<=  '1';	

end sim;
	