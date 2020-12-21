library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity axi_st_slave is 

generic(	AXI_S_BUS_WIDTH : natural := 32);
	
	port(	AXI_S_ARESETn	 : in STD_LOGIC;
			AXI_S_ACLK		 : in STD_LOGIC;
			AXI_S_TDATA		 : in STD_LOGIC_VECTOR(AXI_S_BUS_WIDTH-1 downto 0);
			AXI_S_TVALID	 : in STD_LOGIC;
			AXI_S_TLAST		 : in STD_LOGIC;
			AXI_S_LAST_OUT	 : out STD_LOGIC;
			AXI_S_TREADY	 : out STD_LOGIC;
			AXI_S_OVALID	 : out STD_LOGIC;
			AXI_S_DATA_OUT	 : out STD_LOGIC_VECTOR(AXI_S_BUS_WIDTH-1 downto 0);
			AXI_S_OREADY 	 : in STD_LOGIC;
			AXI_S_BIT_CNT 	 : out integer range 65535 downto 0);
			
end axi_st_slave;


architecture rtl of axi_st_slave is

type state_type is (IDLE, READY, GET_STREAM);
signal state 	: state_type;
signal bit_cnt : NATURAL range 65535 downto 0;
signal tdata_i	: STD_LOGIC_VECTOR(AXI_S_BUS_WIDTH-1 downto 0);
signal tready_i, tvalid_i, oready_i : STD_LOGIC;

begin

AXI_S_TREADY <= tready_i;
AXI_S_BIT_CNT <= bit_cnt;
AXI_S_LAST_OUT <= AXI_S_TLAST;

input_register: process(AXI_S_ACLK)
begin
	if rising_edge(AXI_S_ACLK) then
			tdata_i <= AXI_S_TDATA;
			oready_i <= AXI_S_OREADY;
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
			AXI_S_DATA_OUT <= (others=>'0');
			AXI_S_OVALID <= '0';
		else
			case state is
			when GET_STREAM =>
				AXI_S_OVALID <= '1';
				AXI_S_DATA_OUT <= tdata_i;
			when READY=>
				AXI_S_OVALID <= '0';
				AXI_S_DATA_OUT <= AXI_S_TDATA;
			when others=>
				AXI_S_OVALID <= '0';
				AXI_S_DATA_OUT <= AXI_S_TDATA;
			end case;
		end if;
	end if;
end process;

end rtl;

		