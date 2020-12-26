library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity axi_top is

generic(	AXI_BUS_WIDTH 	: natural := 32);


	port(	AXI_ACLK			: in STD_LOGIC;
			AXI_ARESETn		: in STD_LOGIC;
			AXI_DATA_IN 	: in STD_LOGIC_VECTOR(AXI_BUS_WIDTH-1 downto 0);
			AXI_KEEP_IN		: in STD_LOGIC_VECTOR(AXI_BUS_WIDTH/8 -1 downto 0);
			AXI_KEEP_OUT	: out STD_LOGIC_VECTOR(AXI_BUS_WIDTH/8 -1 downto 0);
			AXI_IVALID 		: in STD_LOGIC;
			AXI_IREADY		: out STD_LOGIC;
			AXI_OVALID 		: out STD_LOGIC;
			AXI_DATA_OUT 	: out STD_LOGIC_VECTOR(AXI_BUS_WIDTH-1 downto 0);
			AXI_OREADY 		: in STD_LOGIC;
			AXI_BIT_CNT_IN	: out INTEGER range 65535 downto 0;
			AXI_BIT_CNT_OUT : out INTEGER range 65535 downto 0;
			AXI_LAST_IN		: in STD_LOGIC);
end axi_top;

architecture structural of axi_top is

signal tlast_i, tready_i, tvalid_i : STD_LOGIC;
signal tdata_i : STD_LOGIC_VECTOR(AXI_BUS_WIDTH-1 downto 0);
signal tkeep_i : STD_LOGIC_VECTOR(AXI_BUS_WIDTH/8 -1 downto 0);

begin

	AXI_MASTER1: entity work.axi_st_master(rtl)
					generic map(AXI_M_BUS_WIDTH=>AXI_BUS_WIDTH)

					port map(AXI_M_ACLK=>AXI_ACLK,
								AXI_M_ARESETn=>AXI_ARESETn,
								AXI_M_TDATA=>tdata_i,
								AXI_M_TVALID=>tvalid_i,
								AXI_M_TREADY=>tready_i,
								AXI_M_TLAST=>tlast_i,
								AXI_M_DATA_IN=>AXI_DATA_IN,
								AXI_M_IVALID=>AXI_IVALID,
								AXI_M_IREADY=>AXI_IREADY,
								AXI_M_BIT_CNT=>AXI_BIT_CNT_IN,
								AXI_M_KEEP_IN=>AXI_KEEP_IN,
								AXI_M_TKEEP=>tkeep_i,
								AXI_M_LAST_IN=>AXI_LAST_IN);

	AXI_SLAVE1:	entity work.axi_st_slave(rtl)
					generic map(AXI_S_BUS_WIDTH=>AXI_BUS_WIDTH)
								
					port map(AXI_S_ACLK=>AXI_ACLK,
								AXI_S_ARESETn=>AXI_ARESETn,
								AXI_S_TDATA=>tdata_i,
								AXI_S_TVALID=>tvalid_i,
								AXI_S_TREADY=>tready_i,
								AXI_S_TLAST=>tlast_i,
								AXI_S_TKEEP=>tkeep_i,
								AXI_S_KEEP_OUT=>AXI_KEEP_OUT,
								AXI_S_OREADY=>AXI_OREADY,
								AXI_S_DATA_OUT=>AXI_DATA_OUT,
								AXI_S_OVALID=>AXI_OVALID,
								AXI_S_BIT_CNT=>AXI_BIT_CNT_OUT);

end structural;
