library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fifo is 

	generic(	FIFO_BUS_WIDTH		: NATURAL := 32;
				FIFO_BUFF_DEPTH	: NATURAL := 16);

		port(	FIFO_RESETn			: in STD_LOGIC;
				FIFO_CLK				: in STD_LOGIC;
				FIFO_DATA_IN		: in STD_LOGIC_VECTOR(FIFO_BUS_WIDTH -1 downto 0);
				FIFO_WRITE_EN		: in STD_LOGIC;
				FIFO_READ_EN		: in STD_LOGIC;
				FIFO_DATA_OUT		: out STD_LOGIC_VECTOR(FIFO_BUS_WIDTH -1 downto 0);
				FIFO_EMPTY			: out STD_LOGIC;
				FIFO_FULL			: out STD_LOGIC;
				FIFO_NEXT_FULL		: out STD_LOGIC;
				FIFO_NEXT_EMPTY	: out STD_LOGIC);
				
end fifo;

architecture rtl of fifo is

subtype 	word	is STD_LOGIC_VECTOR(FIFO_BUS_WIDTH-1 downto 0);
type 		mem	is array(FIFO_BUFF_DEPTH - 1 downto 0) of word;

signal 	fifo : mem;

signal	head, tail, elem_cnt : integer range FIFO_BUFF_DEPTH -1 downto 0;
signal 	empty_i, nempty_i, full_i, write_en_i, read_en_i : STD_LOGIC;

signal 	data_i : STD_LOGIC_VECTOR(FIFO_BUS_WIDTH-1 downto 0);

begin

pointers: process(FIFO_CLK)
begin
	if rising_edge(FIFO_CLK) then
		if FIFO_RESETn = '0' then
			head <= 0;
			tail <= 0;
			elem_cnt <= 0;
		else
			if FIFO_READ_EN = '1' and FIFO_WRITE_EN = '1' then
				if head = (FIFO_BUFF_DEPTH-1) then
					head <= 0;
				else
					head <= head + 1;
				end if;
				if tail = (FIFO_BUFF_DEPTH-1) then
					tail <= 0;
				else
					tail <= tail + 1;
				end if;
			else
				if FIFO_READ_EN = '1' and empty_i = '0' then
					elem_cnt <= elem_cnt - 1;
					if tail = (FIFO_BUFF_DEPTH-1) then
						tail <= 0;
					else
						tail <= tail + 1;
					end if;
				end if;
				if FIFO_WRITE_EN = '1' and full_i = '0' then
				elem_cnt <= elem_cnt + 1;
					if head = (FIFO_BUFF_DEPTH-1) then
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
			nempty_i 	<= '1';
			empty_i 		<= '1';
			full_i 		<= '0';
		when 1 =>
			nempty_i 	<= '1';
			empty_i 		<= '0';
			full_i 		<= '0';
		when FIFO_BUFF_DEPTH - 1 =>
			nempty_i 	<= '0';
			empty_i 		<= '0';
			full_i 		<= '1';
		when others =>
			nempty_i 	<= '0';
			empty_i 		<= '0';
			full_i		<= '0';
	end case;
end process;

next_full_proc: process(elem_cnt)
begin
	if elem_cnt >= (FIFO_BUFF_DEPTH - 5) then
		FIFO_NEXT_FULL <= '1';
	else
		FIFO_NEXT_FULL <= '0';
	end if;
end process;


FIFO_EMPTY <= empty_i;
FIFO_FULL <= full_i;
FIFO_DATA_OUT 	<= fifo(tail);
fifo(head) <= FIFO_DATA_IN;

/*
data_in_out: process(FIFO_CLK)
begin
	if rising_edge(FIFO_CLK) then
		--FIFO_DATA_OUT <= fifo(tail);
		if FIFO_WRITE_EN then
			fifo(head) <= FIFO_DATA_IN;
		end if;
	end if;
end process;
*/

nempty_out: process(FIFO_CLK)
begin
	if rising_edge(FIFO_CLK) then
		if not(FIFO_RESETn) then
			FIFO_NEXT_EMPTY <= '0';
		else	
			FIFO_NEXT_EMPTY <= nempty_i;
		end if;
	end if;
end process;

end rtl;

	
	