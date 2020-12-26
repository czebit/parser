library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity parser_top is

generic(	BUS_WIDTH 	: natural := 32;
			BUFF_DEPTH	: natural := 16);

	port(	CLK					: in STD_LOGIC;
			RESETn				: in STD_LOGIC;
			TDATA_IN 			: in STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0);
			TVALID_IN 			: in STD_LOGIC;
			TREADY_IN			: out STD_LOGIC;
			TLAST_IN				: in STD_LOGIC;
			TDATA_OUT			: out STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0);
			TVALID_OUT 			: out STD_LOGIC;
			TREADY_OUT			: in STD_LOGIC;
			TLAST_OUT			: out STD_LOGIC;
			BUFF_IN_EMPTY		: out STD_LOGIC;
			BUFF_IN_OVERFLOW	: out STD_LOGIC;
			BUFF_OUT_EMPTY		: out STD_LOGIC;
			BUFF_OUT_OVERFLOW	: out STD_LOGIC;
			AXI_BIT_CNT_IN		: out INTEGER range 65535 downto 0;
			AXI_BIT_CNT_OUT	: out INTEGER range 65535 downto 0);
			
end parser_top;

architecture structural of parser_top is

signal axi_m_ivalid_i, axi_s_oready_i, fifo_out_full_i, fifo_in_empty_i, fifo_out_empty_i, axi_m_iready_i, parser_valid_i, parser_write_en_i, fifo_next_empty_i, parser_ready_i, axi_s_ovalid_i, fifo_in_next_full_i, axi_out_valid_i : STD_LOGIC;
signal parser_header_data_out_i, axi_s_data_out_i, fifo_in_data_out_i, parser_data_out_i, fifo_out_data_out_i : STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0);

begin

	axi_s_oready_i <= not(fifo_in_next_full_i);
	parser_write_en_i <= not(fifo_in_empty_i);
	axi_m_ivalid_i <= not(fifo_out_empty_i);
	
	AXI_ST_SLAVE_IN: entity work.axi_st_slave(rtl)
		generic map(AXI_S_BUS_WIDTH=>BUS_WIDTH)					
		port map(	AXI_S_ARESETn=>RESETn,
						AXI_S_ACLK=>CLK,
						AXI_S_TKEEP=>"1111",
						AXI_S_TDATA=>TDATA_IN,
						AXI_S_TVALID=>TVALID_IN,
						AXI_S_TLAST=>TLAST_IN,
						AXI_S_LAST_OUT=>open,
						AXI_S_TREADY=>TREADY_IN,
						AXI_S_OVALID=>axi_s_ovalid_i,
						AXI_S_DATA_OUT=>axi_s_data_out_i,
						AXI_S_OREADY=>axi_s_oready_i,
						AXI_S_BIT_CNT=>AXI_BIT_CNT_IN);

	FIFO_IN: entity work.fifo(rtl)
		generic map(FIFO_BUS_WIDTH=>BUS_WIDTH,
						FIFO_BUFF_DEPTH=>BUFF_DEPTH)
		port map(	FIFO_RESETn=>RESETn,
						FIFO_CLK=>CLK,
						FIFO_DATA_IN=>axi_s_data_out_i,
						FIFO_DATA_OUT=>fifo_in_data_out_i,
						FIFO_WRITE_EN=>axi_s_ovalid_i,
						FIFO_READ_EN=>parser_ready_i,
						FIFO_NEXT_EMPTY=>fifo_in_empty_i,
						FIFO_NEXT_FULL=>fifo_in_next_full_i);

	PARSER1: entity work.parser(rtl)
		port map(	RESETn=>RESETn,	
		            CLK=>CLK,
		            PDATA_IN=>fifo_in_data_out_i,
		            PDATA_OUT=>parser_data_out_i,
		            PDATA_H_OUT=>parser_header_data_out_i,
		            PWRITE_EN=>parser_write_en_i,
		            PREADY=>parser_ready_i,
		            PVALID=>parser_valid_i,
		            PLAST=>open,
		            BYTE_CNT=>open,
		            REVISION_NUM=>open,
		            CONCATENATE=>open,
		            MESSAGE_TYPE=>open,
						PAYLOAD_SIZE=>open);

	FIFO_OUT: entity work.fifo(rtl)
		generic map(FIFO_BUS_WIDTH=>BUS_WIDTH,
						FIFO_BUFF_DEPTH=>BUFF_DEPTH)
		port map(	FIFO_RESETn=>RESETn,
		            FIFO_CLK=>CLK,
		            FIFO_DATA_IN=>parser_data_out_i,
		            FIFO_DATA_OUT=>fifo_out_data_out_i,
		            FIFO_WRITE_EN=>parser_valid_i,
		            FIFO_READ_EN=>axi_m_iready_i,
		            FIFO_EMPTY=>open,
		            FIFO_NEXT_FULL=>fifo_out_full_i,
		            FIFO_NEXT_EMPTY=>fifo_out_empty_i);

	AXI_ST_MASTER_OUT: entity work.axi_st_master(rtl)
		generic map(AXI_M_BUS_WIDTH=>BUS_WIDTH)
		port map(	AXI_M_ARESETn=>RESETn,
		            AXI_M_ACLK=>CLK,
		            AXI_M_IVALID=>axi_m_ivalid_i,
		            AXI_M_IREADY=>axi_m_iready_i,
		            AXI_M_DATA_IN=>fifo_out_data_out_i,
		            AXI_M_TREADY=>TREADY_OUT,
		            AXI_M_TVALID=>TVALID_OUT,
		            AXI_M_TDATA=>TDATA_OUT,
		            AXI_M_TLAST=>TLAST_OUT,
		            AXI_M_LAST_IN=>'0',
		            AXI_M_BIT_CNT=>AXI_BIT_CNT_OUT,
						AXI_M_KEEP_IN=>"1111" );

end structural;