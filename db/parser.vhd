library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity parser is 
		port(	RESETn			: in STD_LOGIC;
				CLK				: in STD_LOGIC;
				PDATA_IN			: in STD_LOGIC_VECTOR(31 downto 0);
				PDATA_OUT		: out STD_LOGIC_VECTOR(31 downto 0);
				PDATA_H_OUT		: out STD_LOGIC_VECTOR(31 downto 0);
				PWRITE_EN		: in STD_LOGIC;
				PREADY			: out STD_LOGIC;
				PVALID			: out STD_LOGIC;
				PLAST				: out STD_LOGIC;
				BYTE_CNT			: out integer range 65535 downto 0;
				REVISION_NUM	: out STD_LOGIC_VECTOR(3 downto 0);
				CONCATENATE		: out STD_LOGIC;
				MESSAGE_TYPE	: out STD_LOGIC_VECTOR(7 downto 0);
				PAYLOAD_SIZE	: out STD_LOGIC_VECTOR(15 downto 0);
				state_d, state_d2 : out integer range 0 to 8;
				data_i_d, data_ii_d, data_iii_d,data_iiii_d : out STD_LOGIC_VECTOR(31 downto 0);
				ov, ov2 : out integer range 3 downto 0;
				ov_f, ov_ff, r1, r2, r3, r4 : out STD_LOGIC);
				
end parser;

architecture rtl of parser is

type state_type is (IDLE, SUSPEND, GET_H, GET_D, GET_DD, GET_H_D);
signal	state, state_i, state_last : state_type;

signal 	c_i, c_ii : STD_LOGIC;
signal	write_en_i, write_en_ii, write_en_iii : STD_LOGIC;
signal 	ready, ready2, ready3, ready_i, ready_ii, ready_iii, ready_iiii : STD_LOGIC;
signal	last_i : STD_LOGIC;
signal 	valid_i, valid_ii : STD_LOGIC;
signal	ov_flag_i, ov_flag_ii : STD_LOGIC;
signal 	data_0, data_i, data_ii, data_iii, data_iiii, data_iiiii, data_h_out_i, data_h_out_ii, data_out_i, data_out_ii : STD_LOGIC_VECTOR(31 downto 0);
signal	revision_i, revision_ii : STD_LOGIC_VECTOR(3 downto 0);
signal	mes_type_i, mes_type_ii : STD_LOGIC_VECTOR(7 downto 0);
signal	payload_size_i, payload_size_ii : STD_LOGIC_VECTOR(15 downto 0);
signal	payload_size_i_mod, payload_size_i_mod_last, payload_shift_i, payload_shift_ii : integer range 3 downto 0;
signal	bytes_cnt_i, bytes_cnt_i_n, bytes_cnt_i_nn, payload_size_i_int : integer range 65535 downto 0;
signal	overflow_last, overflow_i, overflow_ii : integer range 3 downto 0;


begin
BYTE_CNT 		<= bytes_cnt_i;
--PREADY 			<= write_en_i;
PREADY 			<= PWRITE_EN and write_en_i;
PLAST 			<= last_i;
/*
PDATA_H_OUT 	<= data_h_out_ii;
PDATA_OUT 		<= data_out_ii;
REVISION_NUM	<= revision_ii;
CONCATENATE 	<= c_ii;
MESSAGE_TYPE 	<= mes_type_ii;
PAYLOAD_SIZE 	<= payload_size_ii;
PVALID			<= valid_ii;
*/

PDATA_H_OUT 	<= data_h_out_i;
PDATA_OUT 		<= data_out_i;
REVISION_NUM	<= revision_i;
CONCATENATE 	<= c_i;
MESSAGE_TYPE 	<= mes_type_i;
PAYLOAD_SIZE 	<= payload_size_i;
PVALID			<= valid_i;

data_i_d 		<= data_i;
data_ii_d		<= data_ii;
data_iii_d		<= data_iii;
data_iiii_d		<= data_iiii;

ov					<= payload_shift_i;
ov2 				<= overflow_ii;
ov_f				<= ov_flag_i;
ov_ff				<= ov_flag_ii;
r1<= ready_i;
r2<= ready_ii;
r3<= ready_iii;
r4<= ready_iiii;

state_proc: process(state)
begin
	case state is
		when IDLE => state_d <= 0;
		when GET_H => state_d <= 1;
		when GET_D => state_d <= 2;
		when GET_H_D => state_d <= 3;
		when GET_DD => state_d <= 4;
		when SUSPEND => state_d <= 5;
	end case;
end process;

state_d2_proc: process(state_i, state)
begin
	case state_i is
		when IDLE => state_d2 <= 0;
		when GET_H => state_d2 <= 1;
		when GET_D => state_d2 <= 2;
		when GET_H_D => state_d2 <= 3;
		when GET_DD => state_d2 <= 4;
		when SUSPEND => state_d2 <= 5;
	end case;
	if state'event then
	state_last <= state_i;
	end if;
end process;

registers: process(CLK)
begin
	if rising_edge(CLK) then
		data_0 <= PDATA_IN;
		data_i <= data_0;
		data_ii <= data_i;
		data_iii <= data_ii;
		data_iiii <= data_iii;
		write_en_i <= PWRITE_EN;
		ready_i <= write_en_i;
		ready_ii <= ready_i;
		ready_iii <= ready_ii;
		ready_iiii <= ready_iii;
		data_out_ii <= data_out_i;
		data_h_out_ii <= data_h_out_i;
		payload_size_ii <= payload_size_i;
		revision_ii <= revision_i;
		mes_type_ii <= mes_type_i;
		c_ii <= c_i;
		valid_ii <= valid_i;
		state_i <= state;
	end if;
end process;

ready <= ready_i and ready_ii and ready_iii;
ready2 <= ready_ii and ready_iii and ready_iiii;

state_machine_proc: process(CLK)
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			state <= IDLE;
		else
			case state is
				when IDLE=>
					if ready_i and ready_ii and ready_iii and ready_iiii then
						state <= GET_H;
					else
						state <= IDLE;
					end if;
				when GET_H =>
					if ready then
						state <= GET_D;
					else
						state <= SUSPEND;
					end if;
				when GET_D=>
					if ready then
						if ov_flag_i = '1' and (bytes_cnt_i_n > payload_size_i_int) then
							state <= GET_H_D;
						elsif ov_flag_i = '0' and bytes_cnt_i_n = payload_size_i_int then
							state <= GET_H;
						else
							state <= GET_D;
						end if;
					else
						if ready2 = '1' and ov_flag_i = '1' and bytes_cnt_i_n > payload_size_i_int then
							state <= GET_H_D;
						else
							state <= SUSPEND;
						end if;
					end if;
				when GET_H_D =>
					if ready then
						state <= GET_DD;
					else
						state <= SUSPEND;
					end if;
				when GET_DD =>
					if ready then
						if ov_flag_i = '1' and (bytes_cnt_i_nn > payload_size_i_int) and (4 - payload_shift_ii < payload_size_i_mod) then
								ov_flag_ii <= '1';
								state <= SUSPEND;
						elsif ov_flag_i = '1' and bytes_cnt_i_n > payload_size_i_int then
							state <= GET_H_D;
						elsif ov_flag_i = '0' and  bytes_cnt_i_n = payload_size_i_int then
							state <= GET_H;
						else
							state <= GET_DD;
						end if;
					else
						if ready2 = '1' and ov_flag_i = '1' and bytes_cnt_i_n > payload_size_i_int then
							state <= GET_H_D;
						else
							state <= SUSPEND;
						end if;
					end if;
				when SUSPEND=>
					case state_last is
						when GET_H =>
							if ready then
								state <= GET_D;
							else
								state <= SUSPEND;
							end if;
						when GET_D =>
							if ready then
								if ov_flag_i = '1' and bytes_cnt_i > payload_size_i_int then
									state <= GET_H_D;
								elsif ov_flag_i = '0' and bytes_cnt_i = payload_size_i_int then
									state <= GET_H;
								else
									state <= GET_D;
								end if;
							else
								state <= SUSPEND;
							end if;
						when GET_H_D =>
							if ready then
								state <= GET_DD;
							else
								state <= SUSPEND;
							end if;
						when GET_DD =>	
							if ready then
								if ov_flag_i = '1' and bytes_cnt_i_n > payload_size_i_int then
									state <= GET_H_D;
								elsif ov_flag_i = '0' and bytes_cnt_i = payload_size_i_int then
									state <= GET_H;
								else
									state <= GET_DD;
								end if;
							else
								state <= SUSPEND;
							end if;
						when others =>
							null;
					end case;
			end case;
		end if;
	end if;
end process;

byte_cnt_proc: process(CLK)
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			bytes_cnt_i 	<= 0;
			bytes_cnt_i_n 	<= 0;
			bytes_cnt_i_nn <= 0;
		else
			if state = IDLE then
				bytes_cnt_i 	<= 0;
				bytes_cnt_i_n 	<= 0;
				bytes_cnt_i_nn <= 0;
			elsif state = GET_H or state = GET_H_D then
				bytes_cnt_i 	<= 0;
				bytes_cnt_i_n 	<= 4;
				bytes_cnt_i_nn <= 8;
			elsif state = SUSPEND and (state_i = GET_H or state_i = GET_H_D) then
				bytes_cnt_i 	<= 0 + ((4-payload_shift_ii) mod 4);
				bytes_cnt_i_n 	<= 4 + ((4-payload_shift_ii) mod 4);
				bytes_cnt_i_nn <= 8 + ((4-payload_shift_ii) mod 4);
			elsif (state = GET_D or state = GET_DD) and (state_i = GET_H or state_i = GET_H_D) then
				bytes_cnt_i 	<= bytes_cnt_i 	+ 4 + ((4 - payload_shift_ii) mod 4);
				bytes_cnt_i_n 	<= bytes_cnt_i_n 	+ 4 + ((4 - payload_shift_ii) mod 4);
				bytes_cnt_i_nn <= bytes_cnt_i_nn + 4 + ((4 - payload_shift_ii) mod 4);
			elsif state = SUSPEND then
				bytes_cnt_i 	<= bytes_cnt_i;
				bytes_cnt_i_n 	<= bytes_cnt_i_n;
				bytes_cnt_i_nn <= bytes_cnt_i_nn;
			else
				bytes_cnt_i 	<= bytes_cnt_i 	+ 4;
				bytes_cnt_i_n 	<= bytes_cnt_i_n 	+ 4;
				bytes_cnt_i_nn <= bytes_cnt_i_nn + 4;
			end if;
		end if;
	end if;
end process;

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
			payload_size_i_mod_last <= 0;
			payload_shift_i <= 0;
		else
			if state = GET_H then
				revision_i			<= data_iii(31 downto 28);
				c_i					<= data_iii(24);
				mes_type_i			<= data_iii(23 downto 16);
				payload_size_i		<= data_iii(15 downto 0);
				payload_size_i_int<= to_integer(unsigned(data_iii(15 downto 0)));
				payload_size_i_mod<= to_integer(unsigned(data_iii(15 downto 0))) mod 4;
				payload_size_i_mod_last <= payload_size_i_mod;
				payload_shift_i <= (payload_shift_i + to_integer(unsigned(data_iii(15 downto 0)))) mod 4;
				payload_shift_ii <= payload_shift_i;
			elsif state = GET_H_D then
			payload_shift_ii <= payload_shift_i;
			payload_size_i_mod_last <= payload_size_i_mod;
				case payload_shift_i is
					when 3 =>
						revision_i			<= data_iiii(7 downto 4);
						c_i					<= data_iiii(1);
						mes_type_i			<= data_iii(31 downto 24);
						payload_size_i		<= data_iii(23 downto 8);
						payload_size_i_int<= to_integer(unsigned(data_iii(23 downto 8)));
						payload_size_i_mod<= to_integer(unsigned(data_iii(23 downto 8))) mod 4;
						payload_shift_i <= (payload_shift_i + to_integer(unsigned(data_iii(23 downto 8)))) mod 4;
					when 2 =>
						revision_i			<= data_iiii(15 downto 12);
						c_i					<= data_iiii(8);
						mes_type_i			<= data_iiii(7 downto 0);
						payload_size_i		<= data_iii(31 downto 16);
						payload_size_i_int<= to_integer(unsigned(data_iii(31 downto 16)));
						payload_size_i_mod<= to_integer(unsigned(data_iii(31 downto 16))) mod 4;
						payload_shift_i <= (payload_shift_i + to_integer(unsigned(data_iii(31 downto 16)))) mod 4;
					when 1 =>
						revision_i			<= data_iiii(23 downto 20);
						c_i					<= data_iiii(16);
						mes_type_i			<= data_iiii(15 downto 8);
						payload_size_i		<= data_iiii(7 downto 0) & data_iii(31 downto 24);
						payload_size_i_int<= to_integer(unsigned(data_iiii(7 downto 0) & data_iii(31 downto 24)));
						payload_size_i_mod<= to_integer(unsigned(data_iiii(7 downto 0) & data_iii(31 downto 24))) mod 4;
						payload_shift_i <= (payload_shift_i + to_integer(unsigned(data_iiii(7 downto 0) & data_iii(31 downto 24)))) mod 4;
					when others =>
						revision_i 			<= revision_i;
						c_i					<= c_i;
						mes_type_i			<= mes_type_i;
						payload_size_i		<= payload_size_i;
						payload_size_i_int<= payload_size_i_int;
						payload_size_i_mod<= payload_size_i_mod;
						payload_shift_i <= payload_shift_i;
				end case;
			else
				revision_i			<= revision_i;
				c_i					<= c_i;
				mes_type_i			<= mes_type_i;
				payload_size_i		<= payload_size_i;
				payload_size_i_int<= payload_size_i_int;
				payload_size_i_mod<= payload_size_i_mod;
				payload_size_i_mod_last <= payload_size_i_mod_last;
				payload_shift_i 	<= payload_shift_i;
				payload_shift_ii 	<= payload_shift_ii;
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
				when GET_H_D=>
					data_out_i <= (others=>'0');
					case payload_shift_i is
						when 3 =>
							data_out_i <= data_iii(7 downto 0) & data_ii(31 downto 8);
							data_h_out_i <= data_iiii(7 downto 0) & data_iii(31 downto 8);
						when 2 =>
							data_out_i <= data_iii(15 downto 0) & data_ii(31 downto 16);
							data_h_out_i <= data_iiii(15 downto 0) & data_iii(31 downto 16);
						when 1 =>
							data_out_i <= data_iii(23 downto 0) & data_ii(31 downto 24);
							data_h_out_i <= data_iiii(23 downto 0) & data_iii(31 downto 24);
						when others =>
							data_out_i <= (others=>'0');
							data_h_out_i <= (others=>'0');
					end case;
				when GET_DD =>
					data_h_out_i <= data_h_out_i;
					case payload_shift_ii is
						when 3 =>
							data_out_i <= data_iii(7 downto 0) & data_ii(31 downto 8);
						when 2 =>
							data_out_i <= data_iii(15 downto 0) & data_ii(31 downto 16);
						when 1 =>
							data_out_i <= data_iii(23 downto 0) & data_ii(31 downto 24);
						when others =>
							data_out_i <= (others=>'0');
					end case;
				when SUSPEND=>
					data_out_i <= data_out_i;
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
			if state = IDLE or state = SUSPEND or state = GET_H then
				valid_i <= '0';
			else
				valid_i <= '1';
			end if;
		end if;
	end if;
end process;

ov_flag_proc: process(CLK)
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			ov_flag_i	<= '0';
		else
		--	if state_i = GET_H or state_i = GET_H_D then
				if payload_shift_i  > 0 then
					ov_flag_i <= '1';
				else
					ov_flag_i <= '0';
				end if;
		--	else
		--		ov_flag_i <= ov_flag_i;
		--	end if;
		end if;
	end if;
end process;

last_proc: process(CLK)
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			last_i <= '0';
		else
			if ov_flag_i then
				if bytes_cnt_i + 4 > payload_size_i_int and state = GET_H_D then
					last_i <= '1';
				else
					last_i <= '0';
				end if;
			else
				if bytes_cnt_i + 4 > payload_size_i_int then
					last_i <= '1';
				else
					last_i <= '0';
				end if;
			end if;
		end if;
	end if;
end process;


end rtl;