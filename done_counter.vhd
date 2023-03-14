-- Feifan Xu
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--use work.config_pkg.all;
--use work.user_pkg.all;

entity done_counter is
    generic(
        addr_width : natural := 32
    );
    port(
        clk        : in std_logic;
        valid      : in std_logic;
        rst        : in std_logic;
        go         : in std_logic;
        size       : in std_logic_vector(addr_width+1 downto 0);
        done       : out std_logic;
        debug_dc_size_v : out std_logic_vector(addr_width+1 downto 0)
    );
end done_counter;

architecture dc of done_counter is
    type state_t is (INITIAL, GO_1, FINAL);
    signal state_r, next_state_r : state_t;
    signal done_r : std_logic := '0';
    signal size_v, next_size_v : unsigned(addr_width+1 downto 0) := (others => '0');
    signal debug_size_r : std_logic_vector(addr_width+1 downto 0);
begin
    process(rst, clk)
    begin
        if (rst = '1') then
            state_r <= INITIAL;
        elsif (rising_edge(clk)) then
            size_v <= next_size_v;
            state_r <= next_state_r;
        end if;
    end process;

    --process(go, state_r, valid)
    process(state_r, size_v, valid, go)
        --variable size_v : std_logic_vector(addr_width+1 downto 0) := (others => '0');
    begin
        --debug_size_r <= size_v;
        case state_r is
            when INITIAL =>
                done_r <= '0';
                next_size_v <= to_unsigned(0, size_v'length);
                if (go = '1') then
                    next_state_r <= GO_1;
                end if;

            when GO_1 =>
                done_r <= '0';
                if (valid = '1') then
                    next_size_v <= size_v + 1;
                end if;
                --if (size_v /= std_logic_vector(unsigned(size) - 1)) then
                if (size_v /= unsigned(size)) then
                    next_state_r <= GO_1;
                else
                    next_state_r <= FINAL;
                end if;

            when FINAL =>
                done_r <= '1';
                next_size_v <= to_unsigned(0, size_v'length);
                if (go = '1') then
                    done_r <= '0';
                    next_state_r <= GO_1;
                end if;
            end case;
    end process;
    --debug_dc_size_v <= debug_size_r;
    done <= done_r;
end dc;