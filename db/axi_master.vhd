library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity axi_st_master is 

	generic(	BUS_WIDTH : natural := 8);
	
	port(		TDATA		: out STD_LOGIC_VECTOR(BUS_WIDTH*8-1 downto 0);
				TVALID	: out STD_LOGIC;
				TLAST		: out STD_LOGIC;
				TSTRB		: out STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0);
				TKEEP		: out STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0);
				TREADY	: in STD_LOGIC;
				ARESETn	: in STD_LOGIC;
				ACLK		: in STD_LOGIC;
				INT_IN	: in STD_LOGIC_VECTOR(BUS_WIDTH*8-1 downto 0));
end axi_st_master;

architecture rtl of axi_st_master is

signal data	: STD_LOGIC_VECTOR(BUS_WIDTH*8-1 downto 0);
signal valid, last : STD_LOGIC;
signal strb, keep : STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0);

begin

transfer: process(ACLK)
begin
	
	
end process;


TDATA 	<= data;
TVALID 	<= valid;
TSTRB 	<= strb;
TKEEP 	<= keep;

end rtl;

--z axi na bufor/fifo(w miare duży) ze nacznikiem start/stop i po drugiej stronie fifo czytam 128 słowa bitowe  
--maszyna stanów
--inf we: 64bit wejściowy na TDATA, a ramka nie zawsze będzie wyrównana do 64
--szerokie słowo pozwoli na wolniejszy zegar

--po fifo maszynka do parsowania (maszyna stanów)
--w pythonie można napisać model referencyjny