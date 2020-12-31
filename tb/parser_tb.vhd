library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.ALL;

entity parser_tb is 
end parser_tb;

architecture sim of parser_tb is

----------------------------------------------------------

----------------------------------------------------------
---------------Internal testbench signals-----------------
signal CLK, RESETn	:  STD_LOGIC;

signal PDATA_IN : STD_LOGIC_VECTOR(31 downto 0);
signal PWRITE_EN, PREADY, PLAST, PVALID	: STD_LOGIC;
signal PDATA_OUT, PDATA_H_OUT : STD_LOGIC_VECTOR(31 downto 0);
signal BYTE_CNT : integer range 65535 downto 0;
signal PAYLOAD_SIZE	: STD_LOGIC_VECTOR(15 downto 0);
signal MESSAGE_TYPE	: STD_LOGIC_VECTOR(7 downto 0);
signal PKEEP : STD_LOGIC_VECTOR(3 downto 0);
signal REVISION_NUM	: STD_LOGIC_VECTOR(3 downto 0);
signal CONCATENATE : STD_LOGIC;


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
	uut: entity work.parser(rtl)					
	port map		(CLK=>CLK,
					RESETn=>RESETn,
					PDATA_IN=>PDATA_IN,
					PDATA_OUT=>PDATA_OUT,
					PDATA_H_OUT=>PDATA_H_OUT,
					PWRITE_EN=>PWRITE_EN,
					PREADY=>PREADY,
					PLAST=>PLAST,
					BYTE_CNT=>BYTE_CNT,
					REVISION_NUM=>REVISION_NUM,
					CONCATENATE=>CONCATENATE,
					MESSAGE_TYPE=>MESSAGE_TYPE,
					PAYLOAD_SIZE=>PAYLOAD_SIZE,
					PVALID=>PVALID,
					PKEEP=>PKEEP
					);

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
			PDATA_IN <= (others => '0');
		else
			if PREADY and PWRITE_EN then
				if not(endfile(test_file)) then
					line_cnt := line_cnt + 1;
					readline(test_file, test_line);
					hread(test_line, sulv);
					PDATA_IN <= To_StdLogicVector(sulv);
				else
					PDATA_IN <= PDATA_IN;
				end if;
			else
				PDATA_IN <= PDATA_IN;
			end if;
		end if;
	end if;
end process;

----------------------------------------------------------
--write stimulus
----------------------------------------------------------

write_en_proc: process(CLK)
variable i : INTEGER := 0;
begin
	if rising_edge(CLK) then
		if RESETn = '0' then
			PWRITE_EN <= '0';
			i := 0;
		else
			if i = 13 then
				i := 0;
			else
				i := i + 1;
			end if;
			
			if i >= 1 then
				PWRITE_EN <= '1';
			else
				PWRITE_EN <= '0';
			end if;
		end if;
	end if;
end process;

--PREAD_EN <= '1';	

write_payload_file: process(CLK)
variable p_line : line;
variable h_line : line;
variable k_line : line;
begin
	if rising_edge(CLK) then
		if PVALID then
			hwrite(p_line, To_BitVector(PDATA_OUT));
			hwrite(h_line, To_BitVector(PDATA_H_OUT));
			hwrite(k_line, To_BitVector(PKEEP));
			writeline(payload_file, p_line);
			writeline(keep_file, 	k_line);
			writeline(header_file, 	h_line);
		end if;
	end if;
end process;


end sim;
	