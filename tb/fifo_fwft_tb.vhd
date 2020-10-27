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
			TAIL_D		: out NATURAL);
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
					TAIL_D=>TAIL_D);
					
					
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
		WRITE_EN <= '0';
		wait for 10 ns;
		
		for i in 0 to 5 loop
			wait until rising_edge(CLK);
			WRITE_EN <= '1';
			DATA_IN <= STD_LOGIC_VECTOR(UNSIGNED(DATA_IN) + 1);
		end loop;
		
		WRITE_EN <= '0';
		wait for 10 ns;
		
		while (FULL = '0') loop
			wait until rising_edge(CLK);
			WRITE_EN <= '1';
			DATA_IN <= STD_LOGIC_VECTOR(UNSIGNED(DATA_IN) + 1);
		end loop;
		
		WRITE_EN <= '0';
		wait for 5 ns;
		
		for i in 0 to 15 loop
			wait until rising_edge(CLK);
			WRITE_EN <= '1';
			DATA_IN <= STD_LOGIC_VECTOR(UNSIGNED(DATA_IN) + 1);
		end loop;
		
		WRITE_EN <= '0';
		wait for 15 ns;
		
		for i in 0 to 20 loop
			wait until rising_edge(CLK);
			WRITE_EN <= '1';
			DATA_IN <= STD_LOGIC_VECTOR(UNSIGNED(DATA_IN) + 1);
		end loop;
		
		wait;
	end process;
		

----------------------------------------------------------
--read stimulus
----------------------------------------------------------	
	data_out_proc: process
	begin
		READ_EN <= '0';
		wait until FULL = '1';
		
		READ_EN <= '1';
		wait until EMPTY = '1';
		
		READ_EN <= '0';
		wait until FULL = '1';
		
		READ_EN <= '1';
		wait until EMPTY = '1';
		
		READ_EN <= '0';
		wait for 20 ns;
		
		READ_EN <= '1';
		wait for 30 ns;
		
		READ_EN <= '0';
		wait for 20 ns;
		
		wait;
	end process;
	
end sim;