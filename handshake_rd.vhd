-- Yujia Liu (UFID:22808486)
-- Feifan Xu (UFID:97621831)
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--use work.config_pkg.all;
--use work.user_pkg.all;

entity handshake_rd is
    generic(
        addr_width : natural := 32
    );
    port(
        rst             : in std_logic;
        source_clk      : in std_logic;
        destination_clk : in std_logic;
        go_in           : in std_logic;
        start_addr_in   : in std_logic_vector(addr_width-1 downto 0);
        size_in         : in std_logic_vector(addr_width+1 downto 0);
        go_out          : out std_logic; -- useless, delete please
        start_addr_out  : out std_logic_vector(addr_width-1 downto 0);
        size_out        : out std_logic_vector(addr_width+1 downto 0);
        rcv             : out std_logic
    );
end handshake_rd;


architecture hs_v1 of handshake_rd is
    signal rst_syn : std_logic;
    signal rst_syn_1 : std_logic;
    signal rst_syn_2 : std_logic;
    --registers for input
    signal go_in_r : std_logic;
    signal start_addr_in_r : std_logic_vector(addr_width-1 downto 0);
    signal size_in_r : std_logic_vector(addr_width+1 downto 0);
    signal source_en : std_logic;
    --registers for output
    signal go_out_r : std_logic;
    signal start_addr_out_r : std_logic_vector(addr_width-1 downto 0);
    signal size_out_r : std_logic_vector(addr_width+1 downto 0);
    signal destination_en : std_logic;
    --source FSM
    type source_state_t is (SOURCE_INITIAL, SOURCE_SEND, SOURCE_WAIT);
    signal source_state_r : source_state_t;
    signal send : std_logic;
    signal ack  : std_logic;
    --source FSM
    type destination_state_t is (DESTINATION_INITIAL, DESTINATION_ENABLE, DESTINATION_WAIT);
    signal destination_state_r : destination_state_t;
    signal send_syn : std_logic;
    signal send_syn_1 : std_logic;
    signal send_syn_2 : std_logic;
    signal ack_syn  : std_logic;
    signal ack_syn_1  : std_logic; 
    signal ack_syn_2  : std_logic;

    signal rcv_r    : std_logic;
    
begin
    --synthronize rst and send signal
    process(source_clk)
    begin
        if(rising_edge(source_clk)) then
            rst_syn_1 <= rst;
        end if;
    end process;
    process(destination_clk)
    begin
        if(rising_edge(destination_clk)) then
            rst_syn_2 <= rst_syn_1;
            send_syn_1 <= send;
        end if;
    end process;
    process(destination_clk)
    begin
        if(rising_edge(destination_clk)) then
            rst_syn <= rst_syn_2;
            send_syn <= send_syn_1;
        end if;
    end process;

    --synthronize rst and ack signal
    process(source_clk)
        begin
            if(rising_edge(source_clk)) then
                ack_syn_1 <= ack;
            end if;
        end process;
    process(source_clk)
        begin
            if(rising_edge(source_clk)) then
                ack_syn <= ack_syn_1;
            end if;
        end process;

    --datapath for go, start_addr and size signal
    process(rst, source_clk)
    begin
        if (rst = '1') then
            start_addr_in_r <= (others => '0');
            size_in_r <= (others => '0');
        elsif (rising_edge(source_clk)) then
            if (source_en = '1') then
                start_addr_in_r <= start_addr_in;
                size_in_r <= size_in;
            end if;
        end if;
    end process;

    --datapath for go, start_addr and size signal
    process(rst_syn, destination_clk)
    begin
        if (rst_syn = '1') then
            start_addr_out_r <= (others => '0');
            size_out_r <= (others => '0');
        elsif (rising_edge(destination_clk)) then
            if (destination_en = '1') then
                start_addr_out_r <= start_addr_in_r;
                size_out_r <= size_in_r;
            end if;
        end if;
    end process;
    start_addr_out <= start_addr_out_r;
    size_out <= size_out_r;
    --source FSM
    process(rst, source_clk)
    begin
        if (rst = '1') then
            send <= '0';
            source_en <= '1';
            source_state_r <= SOURCE_INITIAL;
        elsif (rising_edge(source_clk)) then
            case source_state_r is
                when SOURCE_INITIAL =>
                    if (go_in = '1') then
                        send <= '1';
                        source_en <= '1';
                        source_state_r <= SOURCE_SEND;
                    else
                        source_state_r <= SOURCE_INITIAL;
                    end if;
                    
                when SOURCE_SEND =>
                    --source_en <= '1';
                    if (ack_syn = '1') then
                        source_en <= '0';
                        send <= '0';
                        source_state_r <= SOURCE_WAIT;
                    else
                        source_state_r <= SOURCE_SEND;
                    end if;

                when SOURCE_WAIT =>
                    if (ack_syn = '1') then
                        source_state_r <= SOURCE_WAIT; 
                    else
                        source_state_r <= SOURCE_INITIAL;
                    end if;
            end case;
        end if;
    end process;

    --destination FSM
    process(rst_syn, destination_clk)
    begin
        if (rst_syn = '1') then
            ack <= '0';
            rcv <= '0';
            destination_en <= '0';
            destination_state_r <= DESTINATION_INITIAL;
        elsif (rising_edge(destination_clk)) then
            case destination_state_r is
                when DESTINATION_INITIAL =>
                    destination_en <= '0';
                    rcv <= '0';
                    if (send_syn = '1') then
                        rcv <= '1';
                        destination_en <= '1';
                        destination_state_r <= DESTINATION_ENABLE;
                    else
                        destination_state_r <= DESTINATION_INITIAL;
                    end if;
                    
                when DESTINATION_ENABLE =>

                    ack <= '1';
                    destination_state_r <= DESTINATION_WAIT;

                    
                 when DESTINATION_WAIT =>
                    if (send_syn = '1') then
                        destination_state_r <= DESTINATION_ENABLE;
                    else
                        ack <= '0';
                        destination_state_r <= DESTINATION_INITIAL;
                    end if;
                when others => null; 
            end case;
        end if;
    end process;
    
    
end hs_v1;

