-- Feifan Xu
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--use work.config_pkg.all;
--use work.user_pkg.all;

entity addr_gen is
    generic(
        addr_width : natural := 32
        );

    port(
        clk         : in std_logic;
        go          : in std_logic;
        rst         : in std_logic;
        size        : in std_logic_vector(addr_width+1 downto 0);
        start_addr  : in std_logic_vector(addr_width-1 downto 0);
        addr_gen_en : in std_logic;

        dram_ready  : in std_logic;
        dram_rd_en  : out std_logic;
        dram_addr   : out std_logic_vector(addr_width-1 downto 0);

        debug_size : out std_logic_vector(addr_width+1 downto 0)
    );

end addr_gen;

architecture ag_counter of addr_gen is
    signal addr_r  : std_logic_vector(addr_width-1 downto 0);
    signal dram_rd_en_r : std_logic;
    signal debug_size_r : std_logic_vector(addr_width+1 downto 0);
    --signal counter_en : std_logic;

    type state_t is (RESET, INITIAL, START, COUNT, COUNT2, STALL, FINAL);
    signal state_r, next_state_r : state_t;
    signal size_v, next_size_v  : unsigned(addr_width+1 downto 0) := (others => '0');
begin
    process(clk, go)
        variable add_v : std_logic_vector(addr_width-1 downto 0) := (others => '0');
    begin
        if (go = '1') then
            add_v := start_addr;
            addr_r <= add_v;
        elsif rising_edge(clk) then
            if (dram_ready = '1' and addr_gen_en = '1') then
                add_v := std_logic_vector(unsigned(add_v) + 1);
                addr_r <= add_v;
                --dram_rd_en_r <= '1';
            end if;
        end if;    
    end process;

    dram_addr <= addr_r;
    dram_rd_en <= dram_rd_en_r;
    debug_size <= debug_size_r;

    process(clk, rst)
    begin
        if (rst = '1') then
            state_r <= RESET;
        elsif(rising_edge(clk)) then
            size_v <= next_size_v;
            state_r <= next_state_r;           
        end if;
    end process;

    process(state_r, dram_ready, addr_gen_en, go, size_v)
    --process(state_r, go)
        --variable size_v  : std_logic_vector(addr_width+1 downto 0) := (others => '0');
    begin
        case state_r is
            when RESET =>
                dram_rd_en_r <= '0';
                if (go = '1') then
                    next_state_r <= INITIAL;
                end if;

            when INITIAL =>
                next_size_v <= to_unsigned(0, size_v'length);
                --debug_size_r <= size_v;
                if (dram_ready = '1' and addr_gen_en = '1' and go = '0') then
                    next_size_v <= size_v + 1;
                    dram_rd_en_r <= '1';
                    next_state_r <= COUNT;
                else
                    next_state_r <= INITIAL;
                end if;

            when COUNT =>
                if (dram_ready = '1' and addr_gen_en = '1') then
                    if (size_v /= unsigned(size)) then
                        dram_rd_en_r <= '1';
                        next_size_v <= size_v + 1;
                        --debug_size_r <= size_v;
                        next_state_r <= COUNT;
                    else
                        dram_rd_en_r <= '0';
                        next_state_r <= FINAL;
                    end if;
                else
                    dram_rd_en_r <= '0';
                    next_state_r <= STALL;
                end if;
                
            when STALL =>
                --dram_rd_en_r <= '0'; 
                if (dram_ready = '0' or addr_gen_en = '0') then
                    dram_rd_en_r <= '0';
                else
                    dram_rd_en_r <= '1';
                    next_state_r <= COUNT;
                end if;

            when FINAL =>
                if (go = '1') then
                    next_state_r <= INITIAL;
                end if;

            when others => null;
        end case;

    end process;

end ag_counter;
