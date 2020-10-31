library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fifo_fwft_tb is 
end fifo_fwft_tb;

architecture sim of fifo_fwft_tb is
----------------------------------------------------------
-------------Unit under test declaration------------------

component fifo_fwft is
	generic(	BUS_WIDTH 	: NATURAL;
				BUFF_DEPTH 	: NATURAL);

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
			TAIL_D		: out NATURAL;
			NEXT_EMPTY	: out STD_LOGIC;
			NEXT_FULL	: out STD_LOGIC);
end component;
----------------------------------------------------------

----------------------------------------------------------
-----------------Constant variables-----------------------

	constant cBUS_WIDTH 	: NATURAL := 8;
	constant cBUFF_DEPTH : NATURAL := 8;
----------------------------------------------------------

----------------------------------------------------------
---------------Internal testbench signals-----------------

	signal CLK			: STD_LOGIC;
	signal RESETn		: STD_LOGIC;
	signal DATA_IN		: STD_LOGIC_VECTOR(cBUS_WIDTH*8-1 downto 0) := (others => '0');
	signal DATA_OUT	: STD_LOGIC_VECTOR(cBUS_WIDTH*8-1 downto 0) := (others => '0');
	signal WRITE_EN	: STD_LOGIC;
	signal READ_EN		: STD_LOGIC;
	signal EMPTY		: STD_LOGIC;
	signal FULL			: STD_LOGIC;
	signal LOAD_CNT	: NATURAL;
	signal HEAD_D		: NATURAL;
	signal TAIL_D		: NATURAL;
	signal NEXT_FULL	: STD_LOGIC;
	signal NEXT_EMPTY	: STD_LOGIC;
	
	subtype 	word	is STD_LOGIC_VECTOR(cBUS_WIDTH*8-1 downto 0);
	type 		mem	is array(100 downto 0) of word;
	
	signal data_w, data_r : mem := (others=>(others=> '0'));
	signal cnt_w, cnt_r : INTEGER range 100 downto 0 := 0;
----------------------------------------------------------
	
begin
----------------------------------------------------------
--Instantiate and port map UUT
----------------------------------------------------------
	uut: fifo_fwft
	generic map	(BUS_WIDTH=>cBUS_WIDTH,
					BUFF_DEPTH=>cBUFF_DEPTH)
	port map		(CLK=>CLK,
					RESETn=>RESETn,
					DATA_IN=>DATA_IN,
					DATA_OUT=>DATA_OUT,
					WRITE_EN=>WRITE_EN,
					READ_EN=>READ_EN,
					EMPTY=>EMPTY,
					FULL=>FULL,
					LOAD_CNT=>LOAD_CNT,
					HEAD_D=>HEAD_D,
					TAIL_D=>TAIL_D,
					NEXT_EMPTY=>NEXT_EMPTY,
					NEXT_FULL=>NEXT_FULL);
					
					
----------------------------------------------------------
--Clock generation
----------------------------------------------------------
	clk_proc: process
	begin
		CLK <= '0';
		wait for 1 ns;
		CLK <= '1';
		wait for 1 ns;
	end process;


----------------------------------------------------------
--Reset stimulus
----------------------------------------------------------
	rst_proc: process
	begin
		RESETn <= '0';
		wait for 5 ns;
		RESETn <= '1';
		wait;
	end process;

----------------------------------------------------------
--write stimulus
----------------------------------------------------------	
	data_in_proc: process
	begin
		for i in 0 to 7 loop
			WRITE_EN <= '0';
			wait for 15 ns;
			wait until rising_edge(CLK);
			while (NEXT_FULL = '0') loop
				WRITE_EN <= '1';
				DATA_IN <= STD_LOGIC_VECTOR(UNSIGNED(DATA_IN) + 1);
				data_w(cnt_w) <= DATA_IN;
				cnt_w <= cnt_w + 1;
				wait until rising_edge(CLK);
			end loop;
		end loop;
		
		wait;
	end process;

----------------------------------------------------------
--read stimulus
----------------------------------------------------------	
	data_out_proc: process
	begin
	for i in 0 to 7 loop
		READ_EN <= '0';
		wait until FULL = '1';
		wait until rising_edge(CLK);
		while (NEXT_EMPTY = '0') loop
			READ_EN <= '1';
			wait until rising_edge(CLK);
		end loop;
		
		READ_EN <= '0';
		wait until FULL = '1';
		wait until rising_edge(CLK);
		while (NEXT_EMPTY = '0') loop
			READ_EN <= '1';
			wait until rising_edge(CLK);
		end loop;
		
	end loop;
	wait;
	end process;


process(CLK)
begin
	if rising_edge(CLK) then
		if READ_EN = '1' then
			data_r(cnt_r) <= DATA_OUT;
			if cnt_r > 1 then
				assert(data_r(cnt_r-1) = data_w(cnt_r-1));
			end if;
			cnt_r <= cnt_r + 1;
		end if;
	end if;
end process;

end sim;