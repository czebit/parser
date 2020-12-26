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

signal data_iiii_d, data_iii_d, data_ii_d, data_i_d, PDATA_IN : STD_LOGIC_VECTOR(31 downto 0);
signal PWRITE_EN, PREADY, PLAST, PVALID	: STD_LOGIC;
signal PDATA_OUT, PDATA_H_OUT : STD_LOGIC_VECTOR(31 downto 0);
signal BYTE_CNT : integer range 65535 downto 0;
signal PAYLOAD_SIZE	: STD_LOGIC_VECTOR(15 downto 0);
signal MESSAGE_TYPE	: STD_LOGIC_VECTOR(7 downto 0);
signal PKEEP : STD_LOGIC_VECTOR(3 downto 0);
signal ov : integer range 3 downto 0;
signal state_d, state_d2 : integer range 0 to 8;
signal REVISION_NUM	: STD_LOGIC_VECTOR(3 downto 0);
signal CONCATENATE, ov_f, ov_ff	: STD_LOGIC;


----------------------------------------------------------
--File handling
----------------------------------------------------------
	file test_file	: text open read_mode is "/X/intelFPGA_lite/20.1/parser/ecpri_frames_gen2.txt";
	file out_file	: text open write_mode is "/X/intelFPGA_lite/20.1/parser/testbench_output.txt";
	
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
					PKEEP=>PKEEP,
					state_d=>state_d, state_d2=>state_d2,
					data_i_d=>data_i_d, data_ii_d=>data_ii_d, data_iii_d=>data_iii_d, data_iiii_d=>data_iiii_d,
					ov=>ov, ov_f=>ov_f, ov_ff=>ov_ff);

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
--read stimulus
----------------------------------------------------------	
/*
read_proc: process(CLK)
variable i : INTEGER := 0;
begin
	if rising_edge(CLK) then
		if RESETn = '0' then
			PREAD_EN <= '0';
			i := 0;
		else
			if i = 14 then
				i := 0;
			else
				i := i + 1;
			end if;
			if i >= 3 then
				PREAD_EN <= '1';
			else
				PREAD_EN <= '0';
			end if;
		end if;
	end if;
end process;
*/
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
			if i = 10 then
				i := 0;
			else
				i := i + 1;
			end if;
			
			if i >= 3 then
				PWRITE_EN <= '1';
			else
				PWRITE_EN <= '0';
			end if;
		end if;
	end if;
end process;

--PREAD_EN <= '1';	


end sim;
	