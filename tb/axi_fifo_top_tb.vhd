library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity axi_fifo_top_tb is
end axi_fifo_top_tb;

architecture sim of axi_fifo_top_tb is
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

signal BUFF_EMPTY, OREADY 		: STD_LOGIC;
signal DATA_OUT 				: STD_LOGIC_VECTOR(cBUS_WIDTH*8-1 downto 0);

signal BIT_CNT_IN, BIT_CNT_OUT : INTEGER;

subtype 	word	is STD_LOGIC_VECTOR(cBUS_WIDTH*8-1 downto 0);
type 		mem	is array(80 downto 0) of word;

signal data_w, data_r : mem := (others=>(others=> '0'));
signal cnt_w, cnt_r : INTEGER range 80 downto 0 := 0;

----------------------------------------------------------

begin
----------------------------------------------------------
--Instantiate and port map UUT
----------------------------------------------------------
	uut: entity work.axi_fifo_top(structural)
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
		wait for 8 ns;
		ARESETn <= '1';
		wait;
	end process;

----------------------------------------------------------
--write stimulus
----------------------------------------------------------	
	data_in_proc: process(ACLK)
	begin
		if rising_edge(ACLK) then
			if not(ARESETn) then
				DATA_IN <= (others=>'0');
			else
				DATA_IN <= STD_LOGIC_VECTOR(UNSIGNED(DATA_IN) + 1);
			end if;
		end if;
	end process;
	
	cnt_w_proc: process(ACLK)
	begin
		if rising_edge(ACLK) then
			if IREADY and IVALID then
				cnt_w <= cnt_w + 1;
			end if;
		end if;
	end process;
	
data_w(cnt_w) <= DATA_IN when IREADY = '1' and IVALID = '1';


----------------------------------------------------------
--ivalid stimulus
----------------------------------------------------------	
	ivalid_proc: process(ACLK)
	variable i : integer := 0;
	begin
		if rising_edge(ACLK) then
			if not(ARESETn) then
				IVALID <= '0';
			else
				if i = 15 then
					i := 0;
				else
					i := i + 1;
				end if;
				if i >= 5 then
					IVALID <= '1';
				else
					IVALID <= '0';
				end if;
			end if;
		end if;
	end process;

----------------------------------------------------------
--read stimulus
----------------------------------------------------------	
	oready_proc: process(ACLK)
	variable i : INTEGER := 0;
	begin
		if rising_edge(ACLK) then
			if not(ARESETn) or BUFF_EMPTY then
				OREADY <= '0';
			else
				if i = 19 then
					i := 0;
				else
					i := i + 1;
				end if;
				if i >= 8 then
					OREADY <= '1';
				else
					OREADY <= '0';
				end if;
			end if;
		end if;
	end process;
	
	
	read_proc: process(ACLK)
	begin
		if rising_edge(ACLK) then
			if OREADY then
				data_r(cnt_r) <= DATA_OUT;
				if cnt_r > 1 then
					assert(data_r(cnt_r-1) = data_w(cnt_r-1));
				end if;
				cnt_r <= cnt_r + 1;
			end if;
		end if;
	end process;

end sim;