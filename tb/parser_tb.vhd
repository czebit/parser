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
signal PREAD_EN, PWRITE_EN, PREADY, PLAST, PVALID	: STD_LOGIC;
signal PDATA_OUT, PDATA_H_OUT : STD_LOGIC_VECTOR(31 downto 0);
signal BYTE_CNT : integer range 65535 downto 0;
signal PAYLOAD_SIZE	: STD_LOGIC_VECTOR(15 downto 0);
signal MESSAGE_TYPE	: STD_LOGIC_VECTOR(7 downto 0);

signal ov : integer range 3 downto 0;
signal state_d, state_d2 : integer range 0 to 7;
signal REVISION_NUM	: STD_LOGIC_VECTOR(3 downto 0);
signal CONCATENATE, ov_f, ov_ff	: STD_LOGIC;
signal pvalid_i, pready_i, plast_i, pwrite_en_i : STD_LOGIC := '0';
signal pdata_out_i : STD_LOGIC_VECTOR(31 downto 0);
subtype 	word	is STD_LOGIC_VECTOR(31 downto 0);
type 		mem	is array(1000 downto 0) of word;
signal data_w, data_r : mem := (others=>(others=> '0'));

signal cnt_w, cnt_r : INTEGER range 1000 downto 0 := 0;

----------------------------------------------------------
--File handling
----------------------------------------------------------
	file test_file	: text open read_mode is "/X/intelFPGA_lite/20.1/parser/ecpri_frames_gen2.txt";

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
					PREAD_EN=>PREAD_EN,
					PWRITE_EN=>PWRITE_EN,
					PREADY=>PREADY,
					PLAST=>PLAST,
					BYTE_CNT=>BYTE_CNT,
					REVISION_NUM=>REVISION_NUM,
					CONCATENATE=>CONCATENATE,
					MESSAGE_TYPE=>MESSAGE_TYPE,
					PAYLOAD_SIZE=>PAYLOAD_SIZE,
					PVALID=>PVALID,
					state_d=>state_d,
					state_d2=>state_d2,
					data_i_d=>data_i_d,
					data_ii_d=>data_ii_d,
					data_iii_d=>data_iii_d,
					data_iiii_d=>data_iiii_d,
					ov=>ov,
					ov_f=>ov_f,
					ov_ff=>ov_ff);

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
			if PREADY and pwrite_en_i then
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
			pwrite_en_i <= '0';
			i := 0;
		else
			if i = 10 then
				i := 0;
			else
				i := i + 1;
			end if;
			
			if i >= 1 then
				pwrite_en_i <= '1';
			else
				pwrite_en_i <= '0';
			end if;
		end if;
	end if;
end process;

PREAD_EN <= '1';	
--pwrite_en_i <= '1';

cnt_w_proc: process(CLK)
begin
	if rising_edge(CLK) then
		if pready_i = '1' and pwrite_en_i = '1' then
			cnt_w <= cnt_w + 1;
		end if;
	end if;
end process;
	
data_w(cnt_w) <= PDATA_IN when pready_i = '1' and pwrite_en_i = '1';


plast_reg: process(CLK)
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			plast_i <= '1';
		else
			if PVALID then
				plast_i <= PLAST;
			end if;
		end if;
	end if;
end process;

pvalid_reg: process(CLK)
begin
	if rising_edge(CLK) then
		pvalid_i <= PVALID;
		pdata_out_i <= PDATA_OUT;
		pready_i <= PREADY;
		PWRITE_EN <= pwrite_en_i;
	end if;
end process;


read_proc2: process(CLK)
begin
	if rising_edge(CLK) then
		if pvalid_i = '1' then
			data_r(cnt_r) <= pdata_out_i;
			cnt_r <= cnt_r + 1;
		elsif plast_i and PVALID then
			data_r(cnt_r) <= PDATA_H_OUT;
			cnt_r <= cnt_r + 1;
		else
			cnt_r <= cnt_r;
		end if;
		if cnt_r > 1 then
			assert(data_r(cnt_r-1) = data_w(cnt_r-1));
		end if;
	end if;
end process;

end sim;
	