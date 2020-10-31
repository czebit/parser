library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fifo_fwft is 

	generic(	BUS_WIDTH	: NATURAL := 6;
				BUFF_DEPTH	: NATURAL := 8);
				
		port(	RESETn		: in STD_LOGIC;
				CLK			: in STD_LOGIC;
				DATA_IN		: in STD_LOGIC_VECTOR(BUS_WIDTH*8-1 downto 0);
				DATA_OUT		: out STD_LOGIC_VECTOR(BUS_WIDTH*8-1 downto 0) := (others=>'0');
				WRITE_EN		: in STD_LOGIC;
				READ_EN		: in STD_LOGIC;
				EMPTY			: out STD_LOGIC;
				FULL			: out STD_LOGIC;
				NEXT_FULL	: out STD_LOGIC;
				NEXT_EMPTY	: out STD_LOGIC;
				HEAD_D		: out NATURAL;
				TAIL_D		: out NAtuRAL;
				LOAD_CNT		: out NATURAL);
				
end fifo_fwft;

architecture rtl of fifo_fwft is
	
subtype 	word	is STD_LOGIC_VECTOR(BUS_WIDTH*8-1 downto 0);
type 		mem	is array(BUFF_DEPTH downto 0) of word;

signal 	fifo : mem;
signal	head, tail : NATURAL range BUFF_DEPTH -1 downto 0 := 0;
signal 	elem_cnt : NATURAL range BUFF_DEPTH downto 0 := 0;
signal 	empty_i, full_i, n_empty_i, n_full_i : STD_LOGIC := '0';

begin

pointers: process(CLK)
begin
	if rising_edge(CLK) then
		if RESETn = '0' then
			head <= 0;
			tail <= 0;
			elem_cnt <= 0;
		else
			if READ_EN = '1' and WRITE_EN = '1' then
				null;
			else
				if READ_EN = '1' and empty_i = '0' then
					elem_cnt <= elem_cnt - 1;
					if tail = (BUFF_DEPTH-1) then
						tail <= 0;
					else
						tail <= tail + 1;
					end if;
				elsif WRITE_EN = '1' and full_i = '0' then
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


flags: process(elem_cnt)
begin
	case elem_cnt is
		when 0 =>
			empty_i 		<= '1';
			n_empty_i 	<= '1';
		when 1 =>
			n_empty_i 	<= '1';
			empty_i 		<= '0';
		when BUFF_DEPTH -1 =>
			n_full_i		<= '1';
			full_i 		<= '1';
		when BUFF_DEPTH - 2 =>
			n_full_i		<= '1';
			full_i		<= '0';
		when others =>
			empty_i 	<= '0';
			full_i 	<= '0';
			n_empty_i <= '0';
			n_full_i  <= '0';
	end case;
end process;


/*
flags: process(CLK)
begin
	if falling_edge(CLK) then
	case elem_cnt is
		when 0 =>
			empty_i 		<= '1';
			n_empty_i 	<= '1';
		when 1 =>
			n_empty_i 	<= '1';
			empty_i 		<= '0';
		when BUFF_DEPTH -1 =>
			n_full_i		<= '1';
			full_i 		<= '1';
		when BUFF_DEPTH - 2 =>
			n_full_i		<= '1';
			full_i		<= '0';
		when others =>
			empty_i 	<= '0';
			full_i 	<= '0';
			n_empty_i <= '0';
			n_full_i  <= '0';
	end case;
	end if;
end process;
*/

/*
with elem_cnt select
	empty_i <= 		'1' when 0,
						'0' when others;
					
with elem_cnt select
	n_empty_i <= 	'1' when 1,
						'1' when 0,
						'0' when others;

with elem_cnt select
	n_full_i <= 	'1' when (BUFF_DEPTH - 2),
						'1' when (BUFF_DEPTH - 1),
						'0' when others;

with elem_cnt select
	full_i <= 		'1' when (BUFF_DEPTH - 1),
						'0' when others;
*/
/*
empty_i <= '1' when elem_cnt = 0 else '0';
n_empty_i <= '1' when elem_cnt = 1 else '0';
full_i <= '1' when elem_cnt = BUFF_DEPTH -1 else '0';
n_full_i <= '1' when elem_cnt = BUFF_DEPTH - 2 else '0';
*/

process(CLK)
begin
	if rising_edge(CLK) then
		if READ_EN = '1' then
			DATA_OUT 	<= fifo(tail);
		end if;
		if WRITE_EN = '1' then
			fifo(head) 	<= DATA_IN;
		end if;
	end if;
end process;

--DATA_OUT 	<= fifo(tail);
--fifo(head) 	<= DATA_IN;

EMPTY			<= empty_i;
FULL			<= full_i;
LOAD_CNT 	<= elem_cnt;
HEAD_D 		<= head;
TAIL_D 		<= tail;
NEXT_EMPTY	<= n_empty_i;
NEXT_FULL	<= n_full_i;

	
end rtl;

	
	