library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fifo_tb is 
end fifo_tb;

architecture sim of fifo_tb is

----------------------------------------------------------
-----------------Constant variables-----------------------

	constant cBUS_WIDTH 	: NATURAL := 32;
	constant cBUFF_DEPTH : NATURAL := 16;
----------------------------------------------------------

----------------------------------------------------------
---------------Internal testbench signals-----------------

	signal FIFO_CLK, FIFO_RESETn	: STD_LOGIC;

	signal FIFO_WRITE_EN	: STD_LOGIC;
	signal FIFO_DATA_IN	: STD_LOGIC_VECTOR(cBUS_WIDTH-1 downto 0) := (others => '0');
	
	signal FIFO_READ_EN	: STD_LOGIC;
	signal FIFO_DATA_OUT	: STD_LOGIC_VECTOR(cBUS_WIDTH-1 downto 0) := (others => '0');
	
	signal FIFO_EMPTY, FIFO_FULL				: STD_LOGIC;
	signal FIFO_NEXT_EMPTY, FIFO_NEXT_FULL	: STD_LOGIC;
	
	subtype 	word	is STD_LOGIC_VECTOR(cBUS_WIDTH-1 downto 0);
	type 		mem	is array(100 downto 0) of word;
	
	signal data_w, data_r : mem := (others=>(others=> '0'));
	signal cnt_w, cnt_r : INTEGER range 100 downto 0 := 0;
	signal read_en_i : STD_LOGIC;
----------------------------------------------------------
	
begin
----------------------------------------------------------
--Instantiate and port map UUT
----------------------------------------------------------
	uut: entity work.fifo(rtl)
	generic map	(FIFO_BUS_WIDTH=>cBUS_WIDTH,
					FIFO_BUFF_DEPTH=>cBUFF_DEPTH)
					
	port map		(FIFO_CLK=>FIFO_CLK,
					FIFO_RESETn=>FIFO_RESETn,
					FIFO_DATA_IN=>FIFO_DATA_IN,
					FIFO_DATA_OUT=>FIFO_DATA_OUT,
					FIFO_WRITE_EN=>FIFO_WRITE_EN,
					FIFO_READ_EN=>FIFO_READ_EN,
					FIFO_EMPTY=>FIFO_EMPTY,
					FIFO_NEXT_EMPTY=>FIFO_NEXT_EMPTY,
					FIFO_NEXT_FULL=>FIFO_NEXT_FULL);

----------------------------------------------------------
--Clock generation
----------------------------------------------------------
	clk_proc: process
	begin
		FIFO_CLK <= '0';
		wait for 1 ns;
		FIFO_CLK <= '1';
		wait for 1 ns;
	end process;


----------------------------------------------------------
--Reset stimulus
----------------------------------------------------------
	rst_proc: process
	begin
		FIFO_RESETn <= '0';
		wait for 5 ns;
		FIFO_RESETn <= '1';
		wait;
	end process;

----------------------------------------------------------
--write stimulus
----------------------------------------------------------	
	data_proc: process(FIFO_CLK)
	begin
		if rising_edge(FIFO_CLK) then
			FIFO_DATA_IN <= STD_LOGIC_VECTOR(UNSIGNED(FIFO_DATA_IN) + 1);
		end if;
	end process;
	
	write_proc: process(FIFO_CLK)
	begin
		if rising_edge(FIFO_CLK) then
			if FIFO_WRITE_EN then
				cnt_w <= cnt_w + 1;
			end if;
		end if;
	end process;

	data_w(cnt_w) <= FIFO_DATA_IN when FIFO_WRITE_EN;
	
	write_en: process(FIFO_CLK)
	variable i : INTEGER := 0;
	begin
		if rising_edge(FIFO_CLK) then
			if FIFO_RESETn = '0' then
				FIFO_WRITE_EN <= '0';
			else
				if i = 13 then
					i := 0;
				else
					i := i + 1;
				end if;
				if i >= 3 then
					FIFO_WRITE_EN <= '1';
				else
					FIFO_WRITE_EN <= '0';
				end if;
			end if;
		end if;
	end process;

	
	read_en: process(FIFO_CLK)
	variable i : INTEGER := 0;
	begin
		if rising_edge(FIFO_CLK) then
			if not(FIFO_RESETn) or FIFO_NEXT_EMPTY then
				FIFO_READ_EN <= '0';
			else
				if i = 15 then
					i := 0;
				else
					i := i + 1;
				end if;
				if i >= 4 then
					FIFO_READ_EN <= '1';
				else
					FIFO_READ_EN <= '0';
				end if;
			end if;
		end if;
	end process;

/*
process(FIFO_CLK)
begin
	if rising_edge(FIFO_CLK) then
		read_en_i <= FIFO_READ_EN;
	end if;
end process;
*/
read_en_i <= FIFO_READ_EN;

process(FIFO_CLK)
begin
	if rising_edge(FIFO_CLK) then
		if read_en_i then
			data_r(cnt_r) <= FIFO_DATA_OUT;
			if cnt_r > 1 then
				assert(data_r(cnt_r-1) = data_w(cnt_r-1));
			end if;
			cnt_r <= cnt_r + 1;
		end if;
	end if;
end process;

end sim;