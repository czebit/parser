library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity axi_top_tb is
end axi_top_tb;

architecture sim of axi_top_tb is
----------------------------------------------------------
-----------------Constant variables-----------------------

constant cBUS_WIDTH 	: NATURAL := 8;
----------------------------------------------------------

----------------------------------------------------------
---------------Internal testbench signals-----------------
signal AXI_ACLK, AXI_ARESETn	:  STD_LOGIC;

signal AXI_IVALID, AXI_IREADY 		: STD_LOGIC;
signal AXI_DATA_IN 		 		: STD_LOGIC_VECTOR(cBUS_WIDTH-1 downto 0);

signal AXI_OVALID, AXI_OREADY 		: STD_LOGIC;
signal AXI_DATA_OUT 				: STD_LOGIC_VECTOR(cBUS_WIDTH-1 downto 0);

signal AXI_BIT_CNT_IN, AXI_BIT_CNT_OUT : INTEGER;
signal AXI_LAST_IN : STD_LOGIC := '0';
signal AXI_KEEP_IN, AXI_KEEP_OUT : STD_LOGIC_VECTOR(cBUS_WIDTH/8 -1 downto 0);
subtype 	word	is STD_LOGIC_VECTOR(cBUS_WIDTH-1 downto 0);
type 		mem	is array(80 downto 0) of word;

signal data_w, data_r : mem := (others=>(others=> '0'));
signal cnt_w, cnt_r : INTEGER range 80 downto 0 := 0;
----------------------------------------------------------

begin
----------------------------------------------------------
--Instantiate and port map UUT
----------------------------------------------------------
	uut: entity work.axi_top(structural)
	generic map	(AXI_BUS_WIDTH=>cBUS_WIDTH)
					
	port map		(AXI_ACLK=>AXI_ACLK,
					 AXI_ARESETn=>AXI_ARESETn,
					 AXI_DATA_IN=>AXI_DATA_IN,
					 AXI_IVALID=>AXI_IVALID,
					 AXI_IREADY=>AXI_IREADY,
					 AXI_OVALID=>AXI_OVALID,
					 AXI_DATA_OUT=>AXI_DATA_OUT,
					 AXI_OREADY=>AXI_OREADY,
					 AXI_BIT_CNT_IN=>AXI_BIT_CNT_IN,
					 AXI_BIT_CNT_OUT=>AXI_BIT_CNT_OUT,
					 AXI_LAST_IN=>AXI_LAST_IN,
					 AXI_KEEP_IN=>AXI_KEEP_IN,
					 AXI_KEEP_OUT=>AXI_KEEP_OUT);

----------------------------------------------------------
--Clock generation
----------------------------------------------------------
	clk_proc: process
	begin
		AXI_ACLK <= '0';
		wait for 1 ns;
		AXI_ACLK <= '1';
		wait for 1 ns;
	end process;


----------------------------------------------------------
--Reset stimulus
----------------------------------------------------------
	rst_proc: process
	begin
		AXI_ARESETn <= '0';
		wait for 8 ns;
		AXI_ARESETn <= '1';
		wait;
	end process;

----------------------------------------------------------
--write stimulus
----------------------------------------------------------	
	data_in_proc: process(AXI_ACLK)
	begin
		if rising_edge(AXI_ACLK) then
			if AXI_ARESETn = '0' then
				AXI_DATA_IN <= (others=>'0');
			else
				AXI_DATA_IN <= STD_LOGIC_VECTOR(UNSIGNED(AXI_DATA_IN) + 1);
			end if;
		end if;
	end process;
	
	cnt_w_proc: process(AXI_ACLK)
	begin
		if rising_edge(AXI_ACLK) then
			if AXI_IREADY = '1' and AXI_IVALID = '1' then
				cnt_w <= cnt_w + 1;
			end if;
		end if;
	end process;
	
data_w(cnt_w) <= AXI_DATA_IN when AXI_IREADY = '1' and AXI_IVALID = '1';


----------------------------------------------------------
--ivalid stimulus
----------------------------------------------------------	
	ivalid_proc: process(AXI_ACLK)
	variable i : integer := 0;
	begin
		if rising_edge(AXI_ACLK) then
			if AXI_ARESETn = '0' then
				AXI_IVALID <= '0';
			else
				if i = 13 then
					i := 0;
				else
					i := i + 1;
				end if;
				if i >= 5 then
					AXI_IVALID <= '1';
				else
					AXI_IVALID <= '0';
				end if;
			end if;
		end if;
	end process;

----------------------------------------------------------
--read stimulus
----------------------------------------------------------	
	read_proc: process(AXI_ACLK)
	variable i : INTEGER := 0;
	begin
		if rising_edge(AXI_ACLK) then
			if AXI_ARESETn = '0' then
				AXI_OREADY <= '0';
				i := 0;
			else
				if i = 19 then
					i := 0;
				else
					i := i + 1;
				end if;
				if i >= 3 then
					AXI_OREADY <= '1';
				else
					AXI_OREADY <= '0';
				end if;
			end if;
		end if;
	end process;

	read_proc2: process(AXI_ACLK)
	begin
		if rising_edge(AXI_ACLK) then
			if AXI_OVALID = '1' then
				data_r(cnt_r) <= AXI_DATA_OUT;
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