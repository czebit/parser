library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity parser_top is

generic(	BUFF_DEPTH			: natural := 32;
			AXI_TUSER_WIDTH 	: natural := 32;
			BUS_WIDTH 			: natural := 32);

	port(	CLK				: in  STD_LOGIC;
			RESETn			: in  STD_LOGIC;
			TDATA_S 			: in  STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0);
			TVALID_S 		: in  STD_LOGIC;
			TLAST_S			: in 	STD_LOGIC;
			TREADY_M			: in 	STD_LOGIC;
			TKEEP_S			: in  STD_LOGIC_VECTOR(BUS_WIDTH/8 -1 downto 0);
			TREADY_S			: out STD_LOGIC;
			TDATA_M			: out STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0);
			TUSER_M			: out STD_LOGIC_VECTOR(AXI_TUSER_WIDTH-1 downto 0);
			TKEEP_M			: out STD_LOGIC_VECTOR(BUS_WIDTH/8 -1 downto 0);
			TVALID_M 		: out STD_LOGIC;
			TLAST_M			: out STD_LOGIC;
			BUFF_EMPTY		: out STD_LOGIC;
			BUFF_OVERFLOW	: out STD_LOGIC;
			BIT_CNT_S		: out INTEGER range 65535 downto 0;
			BIT_CNT_M		: out INTEGER range 65535 downto 0
			);
			
end parser_top;

architecture structural of parser_top is

signal plast_i, pvalid_i, pwrite_en_i, pready_i : STD_LOGIC;
signal axi_m_iready_i , axi_m_ivalid_i : STD_LOGIC;
signal axi_s_oready_i, axi_s_ovalid_i : STD_LOGIC;
signal fin_nempty_i, fnext_empty_i, fin_next_full_i, fout_plast_i, fout_nfull_i, fout_nempty_i, fout_read_en_i : STD_LOGIC;
signal p_h_data_out_i, pdata_out_i, fout_pdata_i, fout_phdata_i : STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0); 
signal axi_s_odata_i, fdata_out_i : STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0);
signal pkeep_i, pkeep_i_r, pkeep_i_rr, fout_pkeep_i : STD_LOGIC_VECTOR(BUS_WIDTH/8 -1 downto 0);


begin
	
	fout_read_en_i	<= '1' when axi_m_iready_i = '1' else '0';
	axi_s_oready_i <= not(fin_next_full_i);
	pwrite_en_i 	<= '1' when fin_nempty_i = '0' and fout_nfull_i = '0' else '0';
	axi_m_ivalid_i <= '1' when (fout_nempty_i = '0') else '0';
	
	AXI_ST_SLAVE_IN: entity work.axi_st_slave(rtl)
		generic map(AXI_S_BUS_WIDTH=>BUS_WIDTH,
						AXI_S_TUSER_WIDTH=>AXI_TUSER_WIDTH)					
		port map(	AXI_S_ARESETn=>RESETn,
						AXI_S_ACLK=>CLK,
						AXI_S_TKEEP=>TKEEP_S,
						AXI_S_TDATA=>TDATA_S,
						AXI_S_TVALID=>TVALID_S,
						AXI_S_TLAST=>TLAST_S,
						AXI_S_OLAST=>open,
						AXI_S_TREADY=>TREADY_S,
						AXI_S_OVALID=>axi_s_ovalid_i,
						AXI_S_ODATA=>axi_s_odata_i,
						AXI_S_OREADY=>axi_s_oready_i,
						AXI_S_CNT=>BIT_CNT_S,
						AXI_S_TUSER=>(others=>'0'),
						AXI_S_OUSER=>open,
						AXI_S_OKEEP=>open
						);

	FIFO_IN: entity work.fifo(rtl)
		generic map(FIFO_BUS_WIDTH=>BUS_WIDTH,
						FIFO_BUFF_DEPTH=>BUFF_DEPTH)
		port map(	FIFO_RESETn=>RESETn,
						FIFO_CLK=>CLK,
						FIFO_DATA_IN=>axi_s_odata_i,
						FIFO_DATA_OUT=>fdata_out_i,
						FIFO_WRITE_EN=>axi_s_ovalid_i,
						FIFO_READ_EN=>pready_i,
						FIFO_NEXT_EMPTY=>fin_nempty_i,
						FIFO_NEXT_FULL=>fin_next_full_i
						);

	PARSER1: entity work.parser(rtl)
		port map(	RESETn=>RESETn,					/* in		reset active low 					*/ 
						CLK=>CLK,							/* in		clock 								*/
						PWRITE_EN=>pwrite_en_i,			/* in 	write enable to parser 			*/ 
		            PDATA_IN=>fdata_out_i,			/* in		ecpri frames input 				*/
		            PDATA_OUT=>pdata_out_i,			/* out	ecpri payload output 			*/ 
		            PDATA_H_OUT=>p_h_data_out_i,	/* out	ecpri header output 			 	*/ 
		            PREADY=>pready_i,					/* out	ready for data					 	*/ 
		            PVALID=>pvalid_i,					/* out	output data valid				  	*/ 
						PKEEP=>pkeep_i,					/* out	keep bytes of PDATA_OUT 	 	*/ 
		            PLAST=>plast_i,					/* out	last byte of payload				*/ 
		            BYTE_CNT=>open,
		            REVISION_NUM=>open,
		            CONCATENATE=>open,
		            MESSAGE_TYPE=>open,
						PAYLOAD_SIZE=>open
						);

	FIFO_OUT: entity work.fifo_out(rtl)
		generic map(FIFO_BUS_WIDTH=>BUS_WIDTH,
						FIFO_BUFF_DEPTH=>BUFF_DEPTH)
		port map(	FIFO_RESETn=>RESETn,
						FIFO_CLK=>CLK,
						FIFO_PDATA_IN=>pdata_out_i,
						FIFO_PHDATA_IN=>p_h_data_out_i,
						FIFO_PKEEP_IN=>pkeep_i,
						FIFO_PLAST_IN=>plast_i,
						FIFO_PDATA_OUT=>fout_pdata_i,
						FIFO_PHDATA_OUT=>fout_phdata_i,
						FIFO_PLAST_OUT=>fout_plast_i,
						FIFO_PKEEP_OUT=>fout_pkeep_i,
						FIFO_WRITE_EN=>pvalid_i,
						FIFO_READ_EN=>fout_read_en_i,
						FIFO_NEXT_EMPTY=>fout_nempty_i,
						FIFO_NEXT_FULL=>fout_nfull_i
						);

	AXI_ST_MASTER_OUT: entity work.axi_st_master(rtl)
		generic map(AXI_M_BUS_WIDTH=>BUS_WIDTH,			/* 		AXI interface bus width 	*/
						AXI_M_TUSER_WIDTH=>AXI_TUSER_WIDTH) /* 		TUSER line width 				*/
		port map(	AXI_M_ARESETn=>RESETn,					/* in		reset active low		 		*/
		            AXI_M_ACLK=>CLK,							/* in		clock								*/
		            AXI_M_IVALID=>axi_m_ivalid_i,			/* in		input	data valid				*/
						AXI_M_TREADY=>TREADY_M,					/* in		slave ready to get data		*/
		            AXI_M_IDATA=>fout_pdata_i,			/* in 	data input						*/
						AXI_M_ILAST=>fout_plast_i,			/* in		last word of packet			*/
						AXI_M_IKEEP=>fout_pkeep_i,			/* in		keep quantifier for tdata	*/
						AXI_M_IUSER=>fout_phdata_i,		/* in		tuser data						*/
		            AXI_M_TVALID=>TVALID_M,					/* out 	master ready to send data	*/
		            AXI_M_TDATA=>TDATA_M,					/* out	data output						*/
		            AXI_M_TLAST=>TLAST_M,					/* out	last word of packet			*/
		            AXI_M_CNT=>BIT_CNT_M,				/* out	send word counter				*/
						AXI_M_TUSER=>TUSER_M,					/* out	tuser data						*/
						AXI_M_IREADY=>axi_m_iready_i,			/* out	axi M ready to get data		*/
						AXI_M_TKEEP=>TKEEP_M						/* out	axi M keep signal				*/
						);

end structural;