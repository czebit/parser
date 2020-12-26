library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity axi_st_master is 

	generic(	AXI_M_BUS_WIDTH : natural := 32);
	
	port(		AXI_M_ARESETn	: in STD_LOGIC;
				AXI_M_ACLK		: in STD_LOGIC;
				AXI_M_IVALID 	: in STD_LOGIC;
				AXI_M_IREADY 	: out STD_LOGIC;
				AXI_M_DATA_IN	: in STD_LOGIC_VECTOR(AXI_M_BUS_WIDTH-1 downto 0);
				AXI_M_TREADY	: in STD_LOGIC;
				AXI_M_TVALID	: out STD_LOGIC;
				AXI_M_TDATA		: out STD_LOGIC_VECTOR(AXI_M_BUS_WIDTH-1 downto 0);
				AXI_M_TLAST		: out STD_LOGIC;
				AXI_M_TKEEP		: out STD_LOGIC_VECTOR(AXI_M_BUS_WIDTH/8 - 1 downto 0);
				AXI_M_KEEP_IN	: in STD_LOGIC_VECTOR(AXI_M_BUS_WIDTH/8 - 1 downto 0);
				AXI_M_LAST_IN	: in STD_LOGIC;
				AXI_M_BIT_CNT	: out INTEGER range 65535 downto 0);
end axi_st_master;

architecture rtl of axi_st_master is

type state_type is (IDLE, SEND_STREAM, SUSPEND);
signal state : state_type;
signal bit_cnt : NATURAL range 65535 downto 0;
signal last_i, tready_i, iready_i, tvalid_i : STD_LOGIC;
signal idata_i : STD_LOGIC_VECTOR(AXI_M_BUS_WIDTH-1 downto 0);
signal ikeep_i : STD_LOGIC_VECTOR(AXI_M_BUS_WIDTH/8 -1 downto 0);

begin

ikeep_i	<= AXI_M_KEEP_IN;
tvalid_i <= AXI_M_IVALID;
idata_i	<= AXI_M_DATA_IN;
iready_i <= AXI_M_TREADY and tvalid_i;

AXI_M_TVALID 	<= tvalid_i;
AXI_M_TDATA 	<= idata_i;
AXI_M_IREADY 	<= iready_i;
AXI_M_TLAST		<= AXI_M_LAST_IN;
AXI_M_BIT_CNT	<= bit_cnt;
AXI_M_TKEEP		<= ikeep_i;

input_register: process(AXI_M_ACLK)
begin
	if rising_edge(AXI_M_ACLK) then
		if AXI_M_ARESETn = '0' then
			tready_i <= '0';
		else
			tready_i <= AXI_M_TREADY;
		end if;
	end if;
end process;


transfer_control_state_machine: process(AXI_M_ACLK)
begin
	if rising_edge(AXI_M_ACLK) then
		if AXI_M_ARESETn = '0' then
			state <= IDLE;
		else
			case state is
				when IDLE=>
					if AXI_M_IVALID = '1' then
						state <= SEND_STREAM;
					else
						state <= IDLE;
					end if;

				when SEND_STREAM=>
					if AXI_M_IVALID = '1' then
						if tready_i = '1' then
							state <= SEND_STREAM;
						else
							state <= SUSPEND;
						end if;
					else
						state <= IDLE;
					end if;

				when SUSPEND=>
					if tready_i = '1' then
						state <= SEND_STREAM;
					else
						state <= SUSPEND;
					end if;
			end case;
		end if;
	end if;
end process;


send_proc: process(AXI_M_ACLK)
begin
	if rising_edge(AXI_M_ACLK) then
		if AXI_M_ARESETn = '0' then
			bit_cnt <= 0;
		else
			case state is
				when IDLE =>
					bit_cnt <= bit_cnt;
				when SEND_STREAM =>
					if bit_cnt = 65535 then
						bit_cnt <= 0;
					else
						bit_cnt <= bit_cnt + 1;
					end if;
				when SUSPEND =>
					bit_cnt <= bit_cnt;
				end case;
		end if;
	end if;
end process;

end rtl;
