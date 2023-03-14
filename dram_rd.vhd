-- Feifan Xu
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.config_pkg.all;
use work.user_pkg.all;

entity dram_rd is
    generic(
        addr_width : natural := 15
    );
    port(
        clk_1       : in std_logic;
        clk_2       : in std_logic;
        go          : in std_logic;
        rst_1         : in std_logic;
        size        : in std_logic_vector(addr_width+1 downto 0);
        start_addr  : in std_logic_vector(addr_width-1 downto 0);

        dram_ready  : in std_logic;
        dram_rd_en  : out std_logic;
        dram_addr   : out std_logic_vector(addr_width-1 downto 0);
        dram_rd_data : in std_logic_vector(31 downto 0);
        dram_valid   : in std_logic;
        done         : out std_logic;
        data         : out std_logic_vector(15 downto 0);
        read_en      : in std_logic;
        valid        : out std_logic

        --addr_gen_en : in std_logic -- for test only
    );
end dram_rd;

architecture bhv of dram_rd is

    --constant addr_width : natural := 16;
    
    COMPONENT FIFO_DATA
      PORT (
        rst : IN STD_LOGIC;
        wr_clk : IN STD_LOGIC;
        rd_clk : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC;
        prog_full : OUT STD_LOGIC 
      );
    END COMPONENT;
    
    signal start_addr_r : std_logic_vector(addr_width-1 downto 0);
    signal size_r : std_logic_vector(addr_width+1 downto 0);
    signal checked_size : std_logic_vector(addr_width+1 downto 0);
    signal rcv    : std_logic;
    signal rst_syn   : std_logic;
    signal rst_syn_1 : std_logic;
    signal rst_syn_2 : std_logic;
    signal done_syn   : std_logic;
    signal done_syn_1 : std_logic;
    signal done_syn_2 : std_logic;
    signal fifo_rd_en : std_logic;
    signal addr_gen_en : std_logic;
    signal not_addr_gen_en : std_logic; 
    signal empty : std_logic;
    signal done_r : std_logic;
    signal data_split_1 : std_logic_vector(15 downto 0);
    signal data_split_2 : std_logic_vector(15 downto 0);
    signal data_checked     : std_logic_vector(31 downto 0);
    signal not_empty : std_logic;
    
begin
    data_split_1 <= dram_rd_data(31 downto 16);
    data_split_2 <= dram_rd_data(15 downto 0);
    data_checked(31 downto 16) <= data_split_2;
    data_checked(15 downto 0) <= data_split_1;
    

    U_PARITY_CHECKER : entity work.parity_checker
    generic map(
        addr_width => addr_width
        )
    port map (
        size_in => size,
        size_out => checked_size
        );

    U_DONE_COUNTER : entity work.done_counter
        generic map(
            addr_width => addr_width
            )
        
        port map (
            clk => clk_1,
            valid => not_empty,
            rst => rst_1,
            go => go,
            size => size,
            done => done_r
            );
    fifo_rd_en <= read_en;    
    done <= done_r;            
            
    U_HANDSHAKE : entity work.handshake_rd
        generic map(
            addr_width => addr_width
            )
        port map (
            rst => rst_1,--in
            source_clk => clk_1,--in
            destination_clk => clk_2,--in
            go_in => go,--in
            start_addr_in => start_addr,--in
            size_in => checked_size, --in
            start_addr_out => start_addr_r,--out
            size_out => size_r,--out
            rcv => rcv--out
            );

    U_ADDR_GEN : entity work.addr_gen
        generic map(
            addr_width => addr_width
            )
        port map (
            clk  => clk_2,--in
            rst  => rst_syn,--in
            go   => rcv,--in
            size => size_r,--in
            start_addr  => start_addr_r,--in
            addr_gen_en => addr_gen_en,--in
            dram_rd_en  => dram_rd_en,--out
            dram_ready  => dram_ready,--in
            dram_addr   => dram_addr--out
            );
            
    --fifo ip from vivado library
    FIFO_1 : FIFO_DATA
      PORT MAP (
        rst => done_syn,
        wr_clk => clk_2,
        rd_clk => clk_1,
        din => data_checked,
        wr_en => dram_valid,
        rd_en => fifo_rd_en,
        dout => data,
        --full => full,
        empty => empty,
        prog_full => not_addr_gen_en
      );
      addr_gen_en <= not(not_addr_gen_en);
    process(clk_1)
    begin
        if(rising_edge(clk_1)) then
            rst_syn_1 <= rst_1;
        end if;
    end process;
    process(clk_2)
    begin
        if(rising_edge(clk_2)) then
            rst_syn_2 <= rst_syn_1;
            done_syn_2 <= done_r;
        end if;
    end process;
    process(clk_2)
    begin
        if(rising_edge(clk_2)) then
            rst_syn <= rst_syn_2;
            done_syn <= done_syn_2;
        end if;
    end process;
    
    --valid <= not empty and (not done_r);
    not_empty <= not empty;
    valid <= not empty;

end bhv;