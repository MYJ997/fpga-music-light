library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Debounce is
    port(
        clk      : in  std_logic;  -- 系统时钟（20MHz）
        btn_in   : in  std_logic;  -- 去抖输入，期望高表示按下
        btn_db   : out std_logic   -- 去抖输出，高表示按下
    );
end entity;

architecture rtl of Debounce is
    -- 20MHz * 10ms = 200000 -> 18 bits
    constant CNT_MAX : unsigned(17 downto 0) := to_unsigned(200000 - 1, 18);
    signal sync0, sync1 : std_logic := '0';
    signal count : unsigned(17 downto 0) := (others => '0');
    signal stable : std_logic := '0';
begin
    -- 双触发同步
    process(clk)
    begin
        if rising_edge(clk) then
            sync0 <= btn_in;
            sync1 <= sync0;
        end if;
    end process;

    -- 去抖计数
    process(clk)
    begin
        if rising_edge(clk) then
            if sync1 = stable then
                count <= (others => '0');
            else
                if count = CNT_MAX then
                    stable <= sync1;
                    count <= (others => '0');
                else
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process;

    btn_db <= stable;
end architecture;