library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity parser is 
		port(	RESETn			: in STD_LOGIC;
				CLK				: in STD_LOGIC;
				PWRITE_EN		: in STD_LOGIC;
				PDATA_IN			: in STD_LOGIC_VECTOR(31 downto 0);
				PDATA_OUT		: out STD_LOGIC_VECTOR(31 downto 0);
				PDATA_H_OUT		: out STD_LOGIC_VECTOR(31 downto 0);
				PREADY			: out STD_LOGIC;
				PVALID			: out STD_LOGIC;
				PLAST				: out STD_LOGIC;
				PKEEP				: out STD_LOGIC_VECTOR(3 downto 0);
				BYTE_CNT			: out integer range 65535 downto 0;
				REVISION_NUM	: out STD_LOGIC_VECTOR(3 downto 0);
				CONCATENATE		: out STD_LOGIC;
				MESSAGE_TYPE	: out STD_LOGIC_VECTOR(7 downto 0);
				PAYLOAD_SIZE	: out STD_LOGIC_VECTOR(15 downto 0)
				);
				
end parser;

architecture rtl of parser is

type state_type is (IDLE, SUSPEND, GET_H, GET_D, GET_DD, GET_H_D);
signal	state, state_i, state_last : state_type;

signal 	c_i, c_ii, c_iii : STD_LOGIC;
signal	write_en_i : STD_LOGIC;
signal 	ready, ready_i, ready_ii, ready_iii, ready_iiii : STD_LOGIC;
signal	last_i : STD_LOGIC;
signal 	valid_i, valid_ii : STD_LOGIC;
signal	ov_flag_i, ov_flag_ii : STD_LOGIC;
signal 	data_0, data_i, data_ii, data_iii, data_iiii, data_h_out_i, data_h_out_ii, data_h_out_iii, data_out_i, data_out_ii : STD_LOGIC_VECTOR(31 downto 0);
signal	keep_i : STD_LOGIC_VECTOR(3 downto 0);
signal	revision_i, revision_ii, revision_iii : STD_LOGIC_VECTOR(3 downto 0);
signal	mes_type_i, mes_type_ii, mes_type_iii : STD_LOGIC_VECTOR(7 downto 0);
signal	payload_size_i, payload_size_ii, payload_size_iii : STD_LOGIC_VECTOR(15 downto 0);
signal	payload_size_i_mod, payload_size_i_mod_last, payload_shift_i, payload_shift_ii : integer range 3 downto 0;
signal	bytes_cnt_i, bytes_cnt_i_n, bytes_cnt_i_nn, payload_size_i_int : integer range 65535 downto 0;

begin
BYTE_CNT 		<= bytes_cnt_i;
PREADY 			<= PWRITE_EN and write_en_i;
PLAST 			<= last_i;

PDATA_H_OUT 	<= data_h_out_iii;
PDATA_OUT 		<= data_out_ii;
REVISION_NUM	<= revision_iii;
CONCATENATE 	<= c_iii;
MESSAGE_TYPE 	<= mes_type_iii;
PAYLOAD_SIZE 	<= payload_size_iii;
PVALID			<= valid_ii;
PKEEP 			<= keep_i;

registers: process(CLK)
begin
	if rising_edge(CLK) then
	if PWRITE_EN and write_en_i then
		data_0 <= PDATA_IN;
		data_i <= data_0;
		data_ii <= data_i;
		data_iii <= data_ii;
		data_iiii <= data_iii;
	else
		data_0 <= data_0;
		data_i <= data_i;
		data_ii <= data_ii;
		data_iii <= data_iii;
		data_iiii <= data_iiii;
	end if;
		write_en_i		<= PWRITE_EN;
		ready_i 			<= write_en_i;
		ready_ii 		<= ready_i;
		ready_iii 		<= ready_ii;
		ready_iiii 		<= ready_iii;
		data_out_ii 	<= data_out_i;
		data_h_out_ii 	<= data_h_out_i;
		data_h_out_iii	<= data_h_out_ii;
		payload_size_ii <= payload_size_i;
		payload_size_iii <= payload_size_ii;
		revision_ii 	<= revision_i;
		revision_iii 	<= revision_ii;
		mes_type_ii 	<= mes_type_i;
		mes_type_iii 	<= mes_type_ii;
		c_ii 				<= c_i;
		c_iii 			<= c_ii;
		valid_ii 		<= valid_i;
		state_i 			<= state;
	end if;
end process;

ready <= PWRITE_EN and write_en_i;

state_machine_proc: process(CLK)
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			state <= IDLE;
		else
			case state is
				when IDLE=>
					if PWRITE_EN and write_en_i and ready_i and ready_ii and ready_iii and ready_iiii then
						state <= GET_H;
					else
						state <= IDLE;
					end if;
				when GET_H =>
					state_last <= GET_H;
					if ready then
						state <= GET_D;
					else
						state <= SUSPEND;
					end if;
					
				when GET_D=>
					state_last <= GET_D;
					if ready then
						if ov_flag_i = '1' and (bytes_cnt_i_n > payload_size_i_int) then
							state <= GET_H_D;
						elsif ov_flag_i = '0' and bytes_cnt_i_n = payload_size_i_int then
							state <= GET_H;
						else
							state <= GET_D;
						end if;
					else
						state <= SUSPEND;
					end if;
					
				when GET_H_D =>
					state_last <= GET_H_D;
					if ready then
						state <= GET_DD;
					else
						state <= SUSPEND;
					end if;
					
				when GET_DD =>
					state_last <= GET_DD;
					if ready then
						if ov_flag_i = '1' and bytes_cnt_i_n > payload_size_i_int then
							state <= GET_H_D;
						elsif ov_flag_i = '0' and  bytes_cnt_i_n = payload_size_i_int then
							state <= GET_H;
						else
							state <= GET_DD;
						end if;
					else
						state <= SUSPEND;
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
								if ov_flag_i = '1' and bytes_cnt_i > payload_size_i_int then
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
							state <= SUSPEND;
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
			if ov_flag_i = '1' and (bytes_cnt_i_n > payload_size_i_int) and not(bytes_cnt_i > payload_size_i_int) and (4 - payload_shift_ii < payload_size_i_mod_last) then
				valid_i <= '0';
			elsif state = IDLE or state = SUSPEND or state = GET_H then
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
			if payload_shift_i  > 0 then
				ov_flag_i <= '1';
			else
				ov_flag_i <= '0';
			end if;
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
				if bytes_cnt_i_n >= payload_size_i_int and state = GET_DD  and (4 - payload_shift_ii < payload_size_i_mod_last)then
					last_i <= '1';
				else
					last_i <= '0';
				end if;
			else
				if bytes_cnt_i  >= payload_size_i_int then
					last_i <= '1';
				else
					last_i <= '0';
				end if;
			end if;
		end if;
	end if;
end process;


keep_proc: process(CLK)
begin
	if rising_edge(CLK) then
		if not(RESETn) then
			keep_i <= (others=>'0');
		else
			if ((state_i = GET_D or state_i = GET_DD) and state = SUSPEND and bytes_cnt_i > payload_size_i_int) or state = GET_H_D or state = GET_H or (bytes_cnt_i_n >= payload_size_i_int and (state = GET_DD or state = SUSPEND) and (4 - payload_shift_ii < payload_size_i_mod_last)) or (state = SUSPEND and bytes_cnt_i = payload_size_i_int) then
				case payload_size_i_mod is
					when 1 => keep_i <= "1000";
					when 2 => keep_i <= "1100";
					when 3 => keep_i <= "1110";
					when others => keep_i <= "1111";
				end case;
			else
				keep_i <= "1111";
			end if;
		end if;
	end if;
end process;

end rtl;