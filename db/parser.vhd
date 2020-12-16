library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity parser is 

	generic(	PBUS_WIDTH	: NATURAL := 32);

		port(	RESETn			: in STD_LOGIC;
				CLK				: in STD_LOGIC;
				PDATA_IN			: in STD_LOGIC_VECTOR(PBUS_WIDTH-1 downto 0);
				PDATA_OUT		: out STD_LOGIC_VECTOR(PBUS_WIDTH-1 downto 0);
				PDATA_H_OUT		: out STD_LOGIC_VECTOR(PBUS_WIDTH-1 downto 0);
				PREAD_EN			: in STD_LOGIC;
				PWRITE_EN		: in STD_LOGIC;
				PREADY			: out STD_LOGIC;
				PVALID			: out STD_LOGIC;
				PLAST				: out STD_LOGIC;
				BYTE_CNT			: out integer range 65535 downto 0;
				REVISION_NUM	: out STD_LOGIC_VECTOR(3 downto 0);
				CONCATENATE		: out STD_LOGIC;
				MESSAGE_TYPE	: out STD_LOGIC_VECTOR(7 downto 0);
				PAYLOAD_SIZE	: out STD_LOGIC_VECTOR(15 downto 0);
				state_d : out integer range 0 to 6;
				data_i_d, data_ii_d, data_iii_d : out STD_LOGIC_VECTOR(PBUS_WIDTH-1 downto 0);
				ov : out integer range 7 downto 0;
				ov_f : out STD_LOGIC;
				cyc : out integer range 16383 downto 0);
				
end parser;

architecture rtl of parser is

type state_type is (IDLE, SUSPEND, GET_H, GET_D, GET_DD, GET_H_D, GET_D_H);
signal	state, state_i : state_type;

signal 	c_i, c_i_l, write_en_i, write_en_ii, read_en_i, ready_i, ready_ii, ready_iii, ready_iiii, last, valid_i, valid_i_l, ov_flag : STD_LOGIC;
signal 	data_i, data_ii, data_iii, data_iiii, data_h_out_i, data_h_out_i_l, data_out_i, data_out_i_l : STD_LOGIC_VECTOR(PBUS_WIDTH-1 downto 0);
signal	revision_i, revision_i_l : STD_LOGIC_VECTOR(3 downto 0);
signal	mes_type_i, mes_type_i_l : STD_LOGIC_VECTOR(7 downto 0);
signal	payload_size_i, payload_size_i_l : STD_LOGIC_VECTOR(15 downto 0);
--signal	bytes_cnt_i, bytes_cnt_i_n, bytes_cnt_i_nn, payload_size_i_int : integer range 1720 downto 0;
signal	bytes_cnt_i, bytes_cnt_i_n, bytes_cnt_i_nn, payload_size_i_int : integer range 65535 downto 0;
signal	overflow_i : integer range 7 downto 0;
signal	bcnn_gt_ps, bcn_gt_ps, bc_gt_ps, bcn_eq_ps, bc_eq_ps : STD_LOGIC;
signal	payload_size_i_mod : integer range 3 downto 0;
signal 	cyc_cnt_i, cyc_cnt_i_n, cyc_cnt_i_nn, cyc_num : integer range 16383 downto 0;

begin

PDATA_H_OUT 	<= data_h_out_i_l;
PDATA_OUT 		<= data_out_i_l;
BYTE_CNT 		<= bytes_cnt_i;
REVISION_NUM	<= revision_i_l;
CONCATENATE 	<= c_i_l;
MESSAGE_TYPE 	<= mes_type_i_l;
PAYLOAD_SIZE 	<= payload_size_i_l;
PLAST 			<= last;
PREADY 			<= ready_i;
PVALID			<= valid_i_l;

data_i_d 		<= data_i;
data_ii_d		<= data_ii;
data_iii_d		<= data_iii;
ov 				<= overflow_i;
ov_f				<= ov_flag;
cyc <= cyc_num;
ready_proc: process(CLK)
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			ready_i <= '0';
		else
			ready_i <= write_en_i and read_en_i;
		end if;
	end if;
end process;


registers: process(CLK)
begin
	if rising_edge(CLK) then
		data_i <= PDATA_IN;
		data_ii <= data_i;
		data_iii <= data_ii;
		data_iiii <= data_iii;
		ready_ii <= ready_i;
		ready_iii <= ready_ii;
		ready_iiii <= ready_iii;
		data_out_i_l <= data_out_i;
		data_h_out_i_l <= data_h_out_i;
		read_en_i <= PREAD_EN;
		write_en_i <= PWRITE_EN;
		write_en_ii <= write_en_i;
		payload_size_i_l <= payload_size_i;
		revision_i_l <= revision_i;
		mes_type_i_l <= mes_type_i;
		c_i_l <= c_i;
		valid_i_l <= valid_i;
	end if;
end process;


state_machine_proc: process(CLK)
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			state <= IDLE;
		else
			case state is
				when IDLE=>
				state_d <= 0;
					if ready_iiii and write_en_ii then
						state <= GET_H;
					else
						state <= IDLE;
					end if;
				when GET_H =>
				state_d <= 1;
					if ready_iiii and write_en_ii then
						state <= GET_D;
					else
						state <= SUSPEND;
					end if;
				when GET_D=>
				state_d <= 2;
					if ready_iiii and write_en_ii then
						--if ov_flag = '1' and (bytes_cnt_i_nn > payload_size_i_int) then
						if ov_flag and bcnn_gt_ps then
							state <= GET_D_H;
						--elsif bytes_cnt_i_n = payload_size_i_int then
						elsif bcn_eq_ps then
							state <= GET_H;
						else
							state <= GET_D;
						end if;
					else
						state <= SUSPEND;
					end if;
				when GET_D_H=>
				state_d <= 3;
					if ready_iiii and write_en_ii then
						state <= GET_H_D;
					else
						state <= SUSPEND;
					end if;
				when GET_H_D =>
				state_d <= 4;
					if ready_iiii then
						if payload_size_i_int < bytes_cnt_i_n then
						--if bcn_gt_ps then
							state <= GET_D_H;
						else
							state <= GET_DD;
						end if;
					else
						state <= SUSPEND;
					end if;
				when GET_DD =>
				state_d <= 5;
					if ready_iiii and write_en_ii then
						--if ov_flag = '1' and (bytes_cnt_i_nn > payload_size_i_int) then
						if ov_flag and bcnn_gt_ps then
							state <= GET_D_H;
						--elsif bytes_cnt_i_n = payload_size_i_int then
						elsif bcn_eq_ps then
							state <= GET_H;
						else
							state <= GET_DD;
						end if;
					else
						state <= SUSPEND;
					end if;
				when SUSPEND=>
				state_d <= 6;
					if ready_iiii and write_en_ii then
						--if bytes_cnt_i > payload_size_i_int then
						if bc_gt_ps then
							state <= GET_D_H;
						--elsif bytes_cnt_i = payload_size_i_int then
						elsif bc_eq_ps then
							state <= GET_H;
						else
							state <= GET_D;
						end if;
					else
						state <= SUSPEND;
					end if;
			end case;
		end if;
	end if;
end process;

byte_cnt_proc: process(CLK)
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			bytes_cnt_i <= 0;
			bytes_cnt_i_n <= 0;
			bytes_cnt_i_nn <= 0;
			
			bcnn_gt_ps <= '0';
			bcn_eq_ps <= '0';
			bcn_gt_ps <= '0';
			bc_eq_ps <= '0';
			bc_gt_ps <= '0';
		else
			if state = IDLE then
				bytes_cnt_i <= 0;
				bytes_cnt_i_n <= 0;
				bytes_cnt_i_nn <= 0;
			elsif state = GET_H or state = GET_H_D or state = GET_D_H then
				bytes_cnt_i <= overflow_i;
				bytes_cnt_i_n <= 4 + overflow_i;
				bytes_cnt_i_nn <= 8 + overflow_i;
			elsif state = SUSPEND then
				bytes_cnt_i <= bytes_cnt_i;
				bytes_cnt_i_n <= bytes_cnt_i_n;
				bytes_cnt_i_nn <= bytes_cnt_i_nn;
			else
				bytes_cnt_i <= bytes_cnt_i + 4;
				bytes_cnt_i_n <= bytes_cnt_i_n + 4;
				bytes_cnt_i_nn <= bytes_cnt_i_nn + 4;
			end if;
			if (bytes_cnt_i_nn + 4) > payload_size_i_int then
				bcnn_gt_ps <= '1';
			else
				bcnn_gt_ps <= '0';
			end if;
			if (bytes_cnt_i_n + 4) = payload_size_i_int then
				bcn_eq_ps <= '1';
			else
				bcn_eq_ps <= '0';
			end if;
			if (bytes_cnt_i_n + 4)> payload_size_i_int then
				bcn_gt_ps <= '1';
			else
				bcn_gt_ps <= '0';
			end if;
			if (bytes_cnt_i +4)> payload_size_i_int then
				bc_gt_ps <= '1';
			else
				bc_gt_ps <= '0';
			end if;
			if (bytes_cnt_i + 4) = payload_size_i_int then
				bc_eq_ps <= '1';
			else
				bc_eq_ps <= '0';
			end if;
		end if;
	end if;
end process;
/*
--compare_proc: process(bytes_cnt_i_nn, payload_size_i_int, bytes_cnt_i_n, bytes_cnt_i, RESETn)
compare_proc: process(CLK)
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			bcnn_gt_ps <= '0';
			bcn_eq_ps <= '0';
			bcn_gt_ps <= '0';
			bc_eq_ps <= '0';
			bc_gt_ps <= '0';
		else
			if (bytes_cnt_i_nn + 4) > payload_size_i_int then
				bcnn_gt_ps <= '1';
			else
				bcnn_gt_ps <= '0';
			end if;
			if (bytes_cnt_i_n + 4) = payload_size_i_int then
				bcn_eq_ps <= '1';
			else
				bcn_eq_ps <= '0';
			end if;
			if (bytes_cnt_i_n + 4)> payload_size_i_int then
				bcn_gt_ps <= '1';
			else
				bcn_gt_ps <= '0';
			end if;
			if (bytes_cnt_i +4)> payload_size_i_int then
				bc_gt_ps <= '1';
			else
				bc_gt_ps <= '0';
			end if;
			if (bytes_cnt_i + 4) = payload_size_i_int then
				bc_eq_ps <= '1';
			else
				bc_eq_ps <= '0';
			end if;
		end if;
	end if;
end process;
*/
get_info_proc: process(CLK)
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			revision_i 			<= (others=>'0');
			c_i 					<= '0';
			mes_type_i 			<= (others=>'0');
			payload_size_i		<= (others=>'0');
			payload_size_i_int<= 0;
			payload_size_i_mod<= 0;
		else
			if state = GET_H then
				revision_i			<= data_iii(PBUS_WIDTH-1 downto PBUS_WIDTH-4);
				c_i					<= data_iii(PBUS_WIDTH-8);
				mes_type_i			<= data_iii(PBUS_WIDTH-9 downto PBUS_WIDTH-16);
				payload_size_i		<= data_iii(PBUS_WIDTH-17 downto PBUS_WIDTH-32);
				payload_size_i_int<= to_integer(unsigned(data_iii(PBUS_WIDTH-17 downto PBUS_WIDTH-32)));
				payload_size_i_mod<= to_integer(unsigned(data_iii(PBUS_WIDTH-17 downto PBUS_WIDTH-32))) mod 4;
			elsif state = GET_H_D then
				case overflow_i is
					when 1 =>
						revision_i			<= data_iiii(7 downto 4);
						c_i					<= data_iiii(1);
						mes_type_i			<= data_iii(31 downto 24);
						payload_size_i		<= data_iii(23 downto 8);
						payload_size_i_int<= to_integer(unsigned(data_iii(23 downto 8)));
						payload_size_i_mod<= to_integer(unsigned(data_iii(23 downto 8))) mod 4;
					when 2 =>
						revision_i			<= data_iiii(15 downto 12);
						c_i					<= data_iiii(8);
						mes_type_i			<= data_iiii(7 downto 0);
						payload_size_i		<= data_iii(31 downto 16);
						payload_size_i_int<= to_integer(unsigned(data_iii(31 downto 16)));
						payload_size_i_mod<= to_integer(unsigned(data_iii(31 downto 16))) mod 4;
					when 3 =>
						revision_i			<= data_iiii(23 downto 20);
						c_i					<= data_iiii(16);
						mes_type_i			<= data_iiii(15 downto 8);
						payload_size_i		<= data_iiii(7 downto 0) & data_iii(31 downto 24);
						payload_size_i_int<= to_integer(unsigned(data_iiii(7 downto 0) & data_iii(31 downto 24)));
						payload_size_i_mod<= to_integer(unsigned(data_iiii(7 downto 0) & data_iii(31 downto 24))) mod 4;
					when others =>
						revision_i 			<= revision_i;
						c_i					<= c_i;
						mes_type_i			<= mes_type_i;
						payload_size_i		<= payload_size_i;
						payload_size_i_int<= payload_size_i_int;
						payload_size_i_mod<= payload_size_i_mod;
				end case;
			else
				revision_i			<= revision_i;
				c_i					<= c_i;
				mes_type_i			<= mes_type_i;
				payload_size_i		<= payload_size_i;
				payload_size_i_int<= payload_size_i_int;
				payload_size_i_mod<= payload_size_i_mod;
			end if;
		end if;
	end if;
end process;


output_data_proc: process (CLK)
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			data_h_out_i <= (others=>'0');
			data_out_i <= (others=>'0');
		else
			case state is
				when IDLE=>
					data_out_i 		<= (others=>'0');
					data_h_out_i 	<= (others=>'0');
				when GET_H=>
					data_out_i		<= (others=>'0');
					data_h_out_i	<= data_iii;
				when GET_D=>
					data_out_i 		<= data_iii;
					data_h_out_i 	<= data_h_out_i;
				when GET_D_H=>
					data_h_out_i	<= data_h_out_i;
					case overflow_i is
						when 1 =>
							data_out_i <= (others=>'0');
							data_out_i(PBUS_WIDTH-1 downto 1*8-1) <= data_iii(PBUS_WIDTH-1 downto 1*8-1);
						when 2 =>
							data_out_i <= (others=>'0');
							data_out_i(PBUS_WIDTH-1 downto 2*8-1) <= data_iii(PBUS_WIDTH-1 downto 2*8-1);
						when 3 =>
							data_out_i <= (others=>'0');
							data_out_i(PBUS_WIDTH-1 downto 3*8-1) <= data_iii(PBUS_WIDTH-1 downto 3*8-1);
						when others => data_out_i <= (others=>'0');
					end case;
				when GET_H_D=>
					data_out_i <= (others=>'0');
					case overflow_i is
						when 1 =>
							data_out_i <= data_iii(1*8-1 downto 0) & data_ii(PBUS_WIDTH-1 downto 1*8);
							data_h_out_i <= data_iiii(1*8-1 downto 0) & data_iii(PBUS_WIDTH-1 downto 1*8);
						when 2 =>
							data_out_i <= data_iii(2*8-1 downto 0) & data_ii(PBUS_WIDTH-1 downto 2*8);
							data_h_out_i <= data_iiii(2*8-1 downto 0) & data_iii(PBUS_WIDTH-1 downto 2*8);
						when 3 =>
							data_out_i <= data_iii(3*8-1 downto 0) & data_ii(PBUS_WIDTH-1 downto 3*8);
							data_h_out_i <= data_iiii(3*8-1 downto 0) & data_iii(PBUS_WIDTH-1 downto 3*8);
						when others =>
							data_out_i <= (others=>'0');
							data_h_out_i <= (others=>'0');
					end case;
				when GET_DD =>
					data_h_out_i <= data_h_out_i;
					case overflow_i is
						when 1 =>
							data_out_i <= data_iii(1*8-1 downto 0) & data_ii(PBUS_WIDTH-1 downto 1*8);
						when 2 =>
							data_out_i <= data_iii(2*8-1 downto 0) & data_ii(PBUS_WIDTH-1 downto 2*8);
						when 3 =>
							data_out_i <= data_iii(3*8-1 downto 0) & data_ii(PBUS_WIDTH-1 downto 3*8);
						when others =>
							data_out_i <= (others=>'0');
					end case;
				when SUSPEND=>
					data_out_i	 <= data_out_i;
					data_h_out_i <= data_h_out_i;
			end case;
		end if;
	end if;
end process;

valid_proc: process(CLK)
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			valid_i <= '0';
		else
			case state is
				when IDLE => valid_i <= '0';
				when SUSPEND => valid_i <= '0';
				when GET_H => valid_i <= '0'; 
				when others => valid_i <= '1';
			end case;
		end if;
	end if;
end process;

state_reg: process(CLK)
begin
	if rising_edge(CLK) then
		state_i <= state;
	end if;
end process;

ov_flag_i_proc: process(CLK)
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			ov_flag	<= '0';
		else
			if state_i = GET_H or state_i = GET_H_D then
				if ov_flag then
					if ((payload_size_i_int - overflow_i) mod 4) > 0 then
						ov_flag <= '1';
					else
						ov_flag <= '0';
					end if;
				else
					if payload_size_i_mod > 0 then
						ov_flag <= '1';
					else
						ov_flag <= '0';
					end if;
				end if;
			end if;
		end if;
	end if;
end process;


overflow_i_proc: process(CLK)
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			overflow_i	<= 0;
		else
				--if (bytes_cnt_i_nn > payload_size_i_int) and (state = GET_D or state = GET_DD) then
				if bcnn_gt_ps = '1' and (state = GET_D or state = GET_DD) then
					overflow_i <= (bytes_cnt_i_nn - payload_size_i_int) mod 4;
				else
					overflow_i <= overflow_i;
				end if;
		end if;
	end if;
end process;


last_proc: process(CLK)
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			last <= '0';
		else
			if ov_flag then
				if bytes_cnt_i = overflow_i and state = GET_H_D then
					last <= '1';
				else
					last <= '0';
				end if;
			else
				if bytes_cnt_i_n > payload_size_i_int then
					last <= '1';
				else
					last <= '0';
				end if;
			end if;
		end if;
	end if;
end process;


end rtl;