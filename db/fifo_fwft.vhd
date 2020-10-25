library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fifo_fwft is 

	generic(	BUS_WIDTH	: NATURAL := 8;
				BUFF_DEPTH	: NATURAL := 8);
				
		port(	RESETn		: in STD_LOGIC;
				CLK			: in STD_LOGIC;
				DATA_IN		: in STD_LOGIC_VECTOR(BUS_WIDTH*8-1 downto 0);
				DATA_OUT		: out STD_LOGIC_VECTOR(BUS_WIDTH*8-1 downto 0);
				WRITE_EN		: in STD_LOGIC;
				READ_EN		: in STD_LOGIC;
				EMPTY			: out STD_LOGIC;
				FULL			: out STD_LOGIC;
				LOAD_CNT		: out NATURAL;
				HEAD_D		: out NATURAL;
				TAIL_D		: out NATURAL);
				
end fifo_fwft;
				
architecture rtl of fifo_fwft is
	
subtype 	word	is STD_LOGIC_VECTOR(BUS_WIDTH*8-1 downto 0);
type 		mem	is array(BUFF_DEPTH downto 0) of word;

signal 	fifo : mem;
signal	head, tail, elem_cnt	: NATURAL range BUFF_DEPTH -1 downto 0 := 0;
signal 	empty_i, full_i : STD_LOGIC := '0';

begin

pointers: process(CLK)
begin
	if rising_edge(CLK) then
		if RESETn = '0' then
			head <= 0;
			tail <= 0;
			elem_cnt <= 0;
		else
			if READ_EN = '1' and WRITE_EN = '1' and full_i = '1' then
				if head = (BUFF_DEPTH-1) then
					head <= 0;
				else
					head <= head + 1;
				end if;
				if tail = (BUFF_DEPTH-1) then
					tail <= 0;
				else
					tail <= tail + 1;
				end if;
			else
				if READ_EN = '1' and empty_i = '0' then
					elem_cnt <= elem_cnt - 1;
					if tail = (BUFF_DEPTH-1) then
						tail <= 0;
					else
						tail <= tail + 1;
					end if;
				end if;
				if WRITE_EN = '1' and full_i = '0' then
					elem_cnt <= elem_cnt + 1;
					if head = (BUFF_DEPTH-1) then
						head <= 0;
					else
						head <= head + 1;
					end if;
				end if;
			end if;
		end if;
	end if;
end process;

comb_flags: process(elem_cnt)
begin
	case elem_cnt is
		when 0 =>
			empty_i 	<= '1';
			full_i 	<= '0';
		when BUFF_DEPTH - 1 =>
			empty_i 	<= '0';
			full_i 	<= '1';
		when others =>
			empty_i 	<= '0';
			full_i 	<= '0';
	end case;
end process;

read_mem: process(CLK)
begin
	if rising_edge(CLK) then
		DATA_OUT 	<= fifo(tail);
		fifo(head) 	<= DATA_IN;
	end if;
end process;

EMPTY	<= empty_i;
FULL	<= full_i;
LOAD_CNT <= elem_cnt;
HEAD_D <= head;
TAIL_D <= tail;
	
end rtl;

	
	