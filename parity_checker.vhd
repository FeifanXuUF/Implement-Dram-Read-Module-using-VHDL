-- Feifan Xu
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--use work.config_pkg.all;
--use work.user_pkg.all;

entity parity_checker is
    generic(
        addr_width : natural := 32
    );
    port(
        size_in : in std_logic_vector(addr_width+1 downto 0);
        size_out : out std_logic_vector(addr_width+1 downto 0)
    );
end parity_checker;

architecture pc of parity_checker is
begin
    process(size_in)
        variable size_middle : std_logic_vector(addr_width+1 downto 0) := (others => '0');
    begin
        if (size_in(0) = '0') then
            size_out <= std_logic_vector(shift_right(unsigned(size_in), 1)); -- even
        else
            size_middle := std_logic_vector(shift_right(unsigned(size_in), 1));
            size_out <= std_logic_vector(unsigned(size_middle) + 1); -- odd
        end if;
    end process;
end pc;