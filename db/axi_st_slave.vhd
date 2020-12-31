library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity axi_st_slave is 

	generic(	AXI_S_BUS_WIDTH 	: natural := 32;
				AXI_S_TUSER_WIDTH : natural := 8);
		
	port(		AXI_S_ARESETn	: in STD_LOGIC;
				AXI_S_ACLK		: in STD_LOGIC;
				AXI_S_TDATA		: in STD_LOGIC_VECTOR(AXI_S_BUS_WIDTH-1 downto 0);
				AXI_S_TKEEP		: in STD_LOGIC_VECTOR(AXI_S_BUS_WIDTH/8 -1 downto 0);
				AXI_S_TVALID	: in STD_LOGIC;
				AXI_S_TLAST		: in STD_LOGIC;
				AXI_S_OREADY 	: in STD_LOGIC;
				AXI_S_TUSER		: in STD_LOGIC_VECTOR(AXI_S_TUSER_WIDTH - 1 downto 0);
				AXI_S_OUSER 	: out STD_LOGIC_VECTOR(AXI_S_TUSER_WIDTH - 1 downto 0);
				AXI_S_OKEEP		: out STD_LOGIC_VECTOR(AXI_S_BUS_WIDTH/8 -1 downto 0);
				AXI_S_OLAST		: out STD_LOGIC;
				AXI_S_TREADY	: out STD_LOGIC;
				AXI_S_OVALID	: out STD_LOGIC;
				AXI_S_ODATA		: out STD_LOGIC_VECTOR(AXI_S_BUS_WIDTH-1 downto 0);
				AXI_S_CNT 		: out integer range 65535 downto 0);	
end axi_st_slave;


architecture rtl of axi_st_slave is

type state_type is (IDLE, READY, GET_STREAM);
signal state 	: state_type;
signal bit_cnt : NATURAL range 65535 downto 0;
signal tdata_i	: STD_LOGIC_VECTOR(AXI_S_BUS_WIDTH-1 downto 0);
signal tkeep_i	: STD_LOGIC_VECTOR(AXI_S_BUS_WIDTH/8 -1 downto 0);
signal tready_i, tvalid_i, oready_i, tlast_i : STD_LOGIC;
signal tuser_i	: STD_LOGIC_VECTOR(AXI_S_TUSER_WIDTH - 1 downto 0);
begin

AXI_S_TREADY <= tready_i;
AXI_S_CNT <= bit_cnt;
 

input_register: process(AXI_S_ACLK)
begin
	if rising_edge(AXI_S_ACLK) then
			tkeep_i 	<= AXI_S_TKEEP;
			tdata_i 	<= AXI_S_TDATA;
			oready_i <= AXI_S_OREADY;
			tlast_i	<= AXI_S_TLAST;
			tuser_i	<= AXI_S_TUSER;
	end if;
end process;


process(AXI_S_ACLK)
begin
	if rising_edge(AXI_S_ACLK) then
		if AXI_S_ARESETn = '0' then
			state <= IDLE;
		else
			case state is
				when IDLE=>
					if oready_i = '1' and AXI_S_TVALID = '1' then
						if tready_i = '1' then
							state <= GET_STREAM;
						else
							state <= READY;
						end if;
					else
						state <= IDLE;
					end if;
					
				when READY=>
					if oready_i = '1' and AXI_S_TVALID = '1' then
						if tready_i = '1' then
							state <= GET_STREAM;
						else
							state <= READY;
						end if;
					else
						state <= IDLE;
					end if;
					
				when GET_STREAM=>
					if oready_i = '1' and AXI_S_TVALID = '1' then
						if tready_i = '1' then
							state <= GET_STREAM;
						else
							state <= READY;
						end if;
					else
						state <= IDLE;
					end if;
			end case;
		end if;
	end if;
end process;


get_proc: process(AXI_S_ACLK)
begin
	if rising_edge(AXI_S_ACLK) then
		if AXI_S_ARESETn = '0' then
			bit_cnt <= 0;
		else
			case state is
				when GET_STREAM =>
					if bit_cnt = 65535 then
						bit_cnt <= 0;
					else
						bit_cnt <= bit_cnt + 1;
					end if;
				when others=>
					bit_cnt<=bit_cnt;
				end case;
		end if;
	end if;
end process;


tready_proc: process(AXI_S_ACLK)
begin
	if rising_edge(AXI_S_ACLK) then
		if AXI_S_ARESETn = '0' then
			tready_i <= '0';
		else
			if AXI_S_OREADY = '1' then
				tready_i <= '1';
			else
				tready_i <= '0';
			end if;
		end if;
	end if;
end process;


dvalid_proc: process(AXI_S_ACLK)
begin
	if rising_edge(AXI_S_ACLK) then
		if AXI_S_ARESETn = '0' then
			AXI_S_ODATA <= (others=>'0');
			AXI_S_OVALID <= '0';
		else
			case state is
			when GET_STREAM =>
				AXI_S_OVALID 		<= '1';
				AXI_S_ODATA 	<= tdata_i;
				AXI_S_OKEEP 	<= tkeep_i;
				AXI_S_OLAST		<= tlast_i;
				AXI_S_OUSER		<= tuser_i;
			when READY=>
				AXI_S_OVALID 		<= '0';
				AXI_S_ODATA 	<= AXI_S_TDATA;
				AXI_S_OKEEP 	<= AXI_S_TKEEP;
				AXI_S_OLAST		<= AXI_S_TLAST;
				AXI_S_OUSER		<= AXI_S_TUSER;
			when others=>
				AXI_S_OVALID 		<= '0';
				AXI_S_ODATA 	<= AXI_S_TDATA;
				AXI_S_OKEEP 	<= AXI_S_TKEEP;
				AXI_S_OLAST		<= AXI_S_TLAST;
				AXI_S_OUSER		<= AXI_S_TUSER;
			end case;
		end if;
	end if;
end process;


end rtl;

		