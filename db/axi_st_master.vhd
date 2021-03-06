library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity axi_st_master is 

	generic(	AXI_M_BUS_WIDTH 	: natural := 32;
				AXI_M_TUSER_WIDTH : natural := 8);
	
	port(		AXI_M_ARESETn	: in STD_LOGIC;
				AXI_M_ACLK		: in STD_LOGIC;
				AXI_M_IVALID 	: in STD_LOGIC;
				AXI_M_IUSER		: in STD_LOGIC_VECTOR(AXI_M_TUSER_WIDTH - 1 downto 0);
				AXI_M_IKEEP		: in STD_LOGIC_VECTOR(AXI_M_BUS_WIDTH/8 - 1 downto 0);
				AXI_M_ILAST		: in STD_LOGIC;
				AXI_M_IDATA		: in STD_LOGIC_VECTOR(AXI_M_BUS_WIDTH-1 downto 0);
				AXI_M_TREADY	: in STD_LOGIC;
				AXI_M_IREADY 	: out STD_LOGIC;
				AXI_M_TVALID	: out STD_LOGIC;
				AXI_M_TDATA		: out STD_LOGIC_VECTOR(AXI_M_BUS_WIDTH-1 downto 0);
				AXI_M_TLAST		: out STD_LOGIC;
				AXI_M_TKEEP		: out STD_LOGIC_VECTOR(AXI_M_BUS_WIDTH/8 - 1 downto 0);
				AXI_M_TUSER		: out STD_LOGIC_VECTOR(AXI_M_TUSER_WIDTH - 1 downto 0);
				AXI_M_CNT		: out INTEGER range 65535 downto 0);
end axi_st_master;


architecture rtl of axi_st_master is

type state_type is (IDLE, SEND_STREAM, SUSPEND);
signal state : state_type;
signal transfers_cnt : NATURAL range 65535 downto 0;
signal tready_i : STD_LOGIC;

begin

AXI_M_TUSER		<= AXI_M_IUSER;
AXI_M_TVALID 	<= AXI_M_IVALID;
AXI_M_TDATA 	<= AXI_M_IDATA;
AXI_M_IREADY 	<= AXI_M_TREADY and AXI_M_IVALID;
AXI_M_TLAST		<= AXI_M_ILAST;
AXI_M_CNT		<= transfers_cnt;
AXI_M_TKEEP		<= AXI_M_IKEEP;

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
			transfers_cnt <= 0;
		else
			case state is
				when IDLE =>
					transfers_cnt <= transfers_cnt;
				when SEND_STREAM =>
					if transfers_cnt = 65535 then
						transfers_cnt <= 0;
					else
						transfers_cnt <= transfers_cnt + 1;
					end if;
				when SUSPEND =>
					transfers_cnt <= transfers_cnt;
				end case;
		end if;
	end if;
end process;

end rtl;
