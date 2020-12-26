library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity axi_master_tb is 
end axi_master_tb;

architecture sim of axi_master_tb is

----------------------------------------------------------
-----------------Constant variables-----------------------

constant cAXI_M_BUS_WIDTH 	: NATURAL := 32;
constant keep1 : STD_LOGIC_VECTOR((cAXI_M_BUS_WIDTH/8)-1 downto 0) := "1000";
constant keep2 : STD_LOGIC_VECTOR((cAXI_M_BUS_WIDTH/8)-1 downto 0) := "1100";
constant keep3 : STD_LOGIC_VECTOR((cAXI_M_BUS_WIDTH/8)-1 downto 0) := "1110";
constant keep4 : STD_LOGIC_VECTOR((cAXI_M_BUS_WIDTH/8)-1 downto 0) := "1111";
----------------------------------------------------------

----------------------------------------------------------
---------------Internal testbench signals-----------------

signal AXI_M_ARESETn	 : STD_LOGIC := '0';
signal AXI_M_ACLK		 : STD_LOGIC := '0';
signal AXI_M_IVALID 	 : STD_LOGIC := '0';
signal AXI_M_IREADY   : STD_LOGIC := '0';
signal AXI_M_DATA_IN	 : STD_LOGIC_VECTOR(cAXI_M_BUS_WIDTH-1 downto 0) := (others=>'0');
signal AXI_M_TVALID	 : STD_LOGIC := '0';
signal AXI_M_TREADY	 : STD_LOGIC := '0';
signal AXI_M_TDATA	 : STD_LOGIC_VECTOR(cAXI_M_BUS_WIDTH-1 downto 0);
signal AXI_M_TLAST	 : STD_LOGIC := '0';
signal AXI_M_BIT_CNT	 : INTEGER range 65535 downto 0;
signal AXI_M_LAST_IN	 : STD_LOGIC := '0';
signal AXI_M_TKEEP	 : STD_LOGIC_VECTOR((cAXI_M_BUS_WIDTH/8) -1 downto 0);
signal AXI_M_KEEP_IN	 : STD_LOGIC_VECTOR((cAXI_M_BUS_WIDTH/8) -1 downto 0);
subtype 	word	is STD_LOGIC_VECTOR(cAXI_M_BUS_WIDTH-1 downto 0);
type 		mem	is array(80 downto 0) of word;

signal data_w, data_r : mem := (others=>(others=> '0'));
signal cnt_w, cnt_r : INTEGER range 80 downto 0 := 0;
----------------------------------------------------------

begin
----------------------------------------------------------
--Instantiate and port map UUT
----------------------------------------------------------
	uut: entity work.axi_st_master(rtl)
	generic map	(AXI_M_BUS_WIDTH=>cAXI_M_BUS_WIDTH)
					
	port map		(AXI_M_TDATA=>AXI_M_TDATA,
					AXI_M_TVALID=>AXI_M_TVALID,
					AXI_M_TLAST=>AXI_M_TLAST,
					AXI_M_TREADY=>AXI_M_TREADY,
					AXI_M_ARESETn=>AXI_M_ARESETn,
					AXI_M_ACLK=>AXI_M_ACLK,
					AXI_M_DATA_IN=>AXI_M_DATA_IN,
					AXI_M_IVALID=>AXI_M_IVALID,
					AXI_M_IREADY=>AXI_M_IREADY,
					AXI_M_BIT_CNT=>AXI_M_BIT_CNT,
					AXI_M_LAST_IN=>AXI_M_LAST_IN,
					AXI_M_KEEP_IN=>AXI_M_KEEP_IN,
					AXI_M_TKEEP=>AXI_M_TKEEP,
					AXI_M_TUSER_IN=>(others=>'1')
					);
					
					
----------------------------------------------------------
--Clock generation
----------------------------------------------------------
	clk_proc: process
	begin
		AXI_M_ACLK <= '0';
		wait for 1 ns;
		AXI_M_ACLK <= '1';
		wait for 1 ns;
	end process;


----------------------------------------------------------
--Reset stimulus
----------------------------------------------------------
	rst_proc: process
	begin
		AXI_M_ARESETn <= '0';
		wait for 6 ns;
		AXI_M_ARESETn <= '1';
		wait;
	end process;


----------------------------------------------------------
--write stimulus
----------------------------------------------------------	
	data_proc: process(AXI_M_ACLK)
	begin
		if rising_edge(AXI_M_ACLK) then
			AXI_M_DATA_IN <= STD_LOGIC_VECTOR(UNSIGNED(AXI_M_DATA_IN) + 1);
		end if;
	end process;
	
	AXI_M_DATA_IN_proc: process(AXI_M_ACLK)
	begin
		if rising_edge(AXI_M_ACLK) then
			if AXI_M_IREADY = '1' and AXI_M_IVALID = '1' then
				cnt_w <= cnt_w + 1;
			end if;
		end if;
	end process;

data_w(cnt_w) <= AXI_M_DATA_IN when AXI_M_IREADY and AXI_M_IVALID;

----------------------------------------------------------
--AXI_M_IVALID stimulus
----------------------------------------------------------	
	AXI_M_IVALID_proc: process(AXI_M_ACLK)
	variable i : integer := 0;
	begin
		if rising_edge(AXI_M_ACLK) then
			if not(AXI_M_ARESETn) then
				AXI_M_IVALID <= '0';
			else
				if i = 9 then
					i := 0;
				else
					i := i + 1;
				end if;
				if i >= 2 then
					AXI_M_IVALID <= '1';
				else
					AXI_M_IVALID <= '0';
				end if;
			end if;
		end if;
	end process;

	keep_stim: process(AXI_M_ACLK)
	variable i : INTEGER := 0;
	begin
		if rising_edge(AXI_M_ACLK) then
			if not(AXI_M_ARESETn) then
				AXI_M_KEEP_IN <= (others=>'0');
				i := 0;
			else
				if i = 5 then
					i := 0;
				else
					i := i + 1;
				end if;
				if i = 4 then
					AXI_M_KEEP_IN <= keep1;
				elsif i = 3 then
					AXI_M_KEEP_IN <= keep2;
				elsif i = 2 then
					AXI_M_KEEP_IN <= keep3;
				elsif i = 1 then
					AXI_M_KEEP_IN <= keep4;
				else
					AXI_M_KEEP_IN <= keep1;
				end if;
			end if;
		end if;
	end process;

----------------------------------------------------------
--read & tready stimulus
----------------------------------------------------------	
	read_proc: process(AXI_M_ACLK)
	variable i : INTEGER := 0;
	begin
		if rising_edge(AXI_M_ACLK) then
			if not(AXI_M_ARESETn) then
				AXI_M_TREADY <= '0';
				i := 0;
			else
				if i = 7 then
					i := 0;
				else
					i := i + 1;
				end if;
				if i >= 1 then
					AXI_M_TREADY <= '1';
				else
					AXI_M_TREADY <= '0';
				end if;
			end if;
		end if;
	end process;

	read_proc2: process(AXI_M_ACLK)
	begin
		if rising_edge(AXI_M_ACLK) then
			if AXI_M_TVALID and AXI_M_TREADY then
				cnt_r <= cnt_r + 1;
			else
				cnt_r <= cnt_r;
			end if;
			if cnt_r > 1 then
				assert(data_r(cnt_r-1) = data_w(cnt_r-1));
			end if;
		end if;
	end process;
data_r(cnt_r) <= AXI_M_TDATA when AXI_M_TREADY and AXI_M_TVALID;
end sim;
