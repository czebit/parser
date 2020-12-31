library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity axi_slave_tb is 
end axi_slave_tb;

architecture sim of axi_slave_tb is

----------------------------------------------------------
-----------------Constant variables-----------------------

constant cBUS_WIDTH 	: NATURAL := 32;
----------------------------------------------------------

----------------------------------------------------------
---------------Internal testbench signals-----------------

signal AXI_S_ARESETn	 : STD_LOGIC;
signal AXI_S_ACLK		 : STD_LOGIC;
signal AXI_S_TVALID	 : STD_LOGIC := '0';
signal AXI_S_TREADY	 : STD_LOGIC := '0';
signal AXI_S_TLAST	 : STD_LOGIC := '0';
signal AXI_S_OVALID	 : STD_LOGIC;
signal AXI_S_TDATA	 : STD_LOGIC_VECTOR(cBUS_WIDTH-1 downto 0) := (others=>'0');
signal AXI_S_ODATA : STD_LOGIC_VECTOR(cBUS_WIDTH-1 downto 0) := (others=>'0');
signal AXI_S_OREADY 	 : STD_LOGIC;
signal AXI_S_CNT  : integer range 65535 downto 0;
signal AXI_S_TKEEP	 : STD_LOGIC_VECTOR(cBUS_WIDTH/8 -1 downto 0);
signal AXI_S_OKEEP : STD_LOGIC_VECTOR(cBUS_WIDTH/8 -1 downto 0);

subtype 	word	is STD_LOGIC_VECTOR(cBUS_WIDTH-1 downto 0);
type 		mem	is array(80 downto 0) of word;

signal data_w, data_r : mem := (others=>(others=> '0'));
signal cnt_w, cnt_r : INTEGER range 80 downto 0 := 0;
----------------------------------------------------------

begin
----------------------------------------------------------
--Instantiate and port map UUT
----------------------------------------------------------
	uut: entity work.axi_st_slave(rtl)
	generic map	(AXI_S_BUS_WIDTH=>cBUS_WIDTH)

	port map		(AXI_S_TDATA=>AXI_S_TDATA,
					AXI_S_ODATA=>AXI_S_ODATA,
					AXI_S_TVALID=>AXI_S_TVALID,
					AXI_S_TLAST=>AXI_S_TLAST,
					AXI_S_TREADY=>AXI_S_TREADY,
					AXI_S_ARESETn=>AXI_S_ARESETn,
					AXI_S_ACLK=>AXI_S_ACLK,
					AXI_S_OVALID=>AXI_S_OVALID,
					AXI_S_OREADY=>AXI_S_OREADY,
					AXI_S_CNT=>AXI_S_CNT,
					AXI_S_TKEEP=>AXI_S_TKEEP,
					AXI_S_OKEEP=>AXI_S_OKEEP,
					AXI_S_TUSER=>(others=>'1')
					);


----------------------------------------------------------
--Clock generation
----------------------------------------------------------
	clk_proc: process
	begin
		AXI_S_ACLK <= '0';
		wait for 1 ns;
		AXI_S_ACLK <= '1';
		wait for 1 ns;
	end process;


----------------------------------------------------------
--Reset stimulus
----------------------------------------------------------
	rst_proc: process
	begin
		AXI_S_ARESETn <= '0';
		wait for 10 ns;
		AXI_S_ARESETn <= '1';
		wait;
	end process;


----------------------------------------------------------
--write stimulus
----------------------------------------------------------	
	data_proc: process(AXI_S_ACLK)
	begin
		if rising_edge(AXI_S_ACLK) then
			if AXI_S_ARESETn = '0' then
				AXI_S_TDATA <= (others=>'0');
			else
				AXI_S_TDATA <= STD_LOGIC_VECTOR(UNSIGNED(AXI_S_TDATA) + 1);
			end if;
		end if;
	end process;
	
	data_in_proc: process(AXI_S_ACLK)
	begin
		if rising_edge(AXI_S_ACLK) then
			if AXI_S_TVALID = '1' and AXI_S_TREADY = '1' then
				cnt_w <= cnt_w + 1;
			end if;
		end if;
	end process;
	
	data_w(cnt_w) <= AXI_S_TDATA when AXI_S_TVALID = '1' and AXI_S_TREADY = '1';

----------------------------------------------------------
--valid stimulus
----------------------------------------------------------	
	tvalid_proc: process(AXI_S_ACLK)
	variable i : INTEGER := 0;
	begin
		if rising_edge(AXI_S_ACLK) then
			if AXI_S_ARESETn = '0' then
				AXI_S_TVALID <= '0';
				i := 0;
			else
				if i = 10 then
					i := 0;
				else
					i := i + 1;
				end if;
				if i > 3 then
					AXI_S_TVALID <= '1';
				else
					AXI_S_TVALID <= '0';
				end if;
			end if;
		end if;
	end process;


----------------------------------------------------------
--read stimulus
----------------------------------------------------------	
	read_proc: process(AXI_S_ACLK)
	begin
		if rising_edge(AXI_S_ACLK) then
			if AXI_S_OVALID = '1' then
				data_r(cnt_r) <= AXI_S_ODATA;
				if cnt_r > 1 then
					assert(data_r(cnt_r-1) = data_w(cnt_r-1));
				end if;
				cnt_r <= cnt_r + 1;
			end if;
		end if;
	end process;
	

	full_proc: process(AXI_S_ACLK)
	variable i :integer := 0;
	begin
		if rising_edge(AXI_S_ACLK) then
			if AXI_S_ARESETn = '0' then
				AXI_S_OREADY <= '0';
				i := 0;
			else
				if i = 17 then
					i := 0;
				else
					i := i + 1;
				end if;
				if i > 7 then
					AXI_S_OREADY <= '1';
				else
					AXI_S_OREADY <= '0';
				end if;
			end if;
		end if;
	end process;
	
end sim;
