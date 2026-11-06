library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY CLK_2 IS
PORT(
    CLK : IN STD_LOGIC;                          -- 输入时钟（例如 s5）
    E   : IN STD_LOGIC_VECTOR(14 DOWNTO 0);      -- 分频参数
    C   : OUT STD_LOGIC                          -- 输出时钟（分频）
);
END CLK_2;

ARCHITECTURE A_CLK OF CLK_2 IS
    SIGNAL counter : UNSIGNED(14 DOWNTO 0) := (OTHERS => '0');
    SIGNAL c_reg   : STD_LOGIC := '0';
BEGIN
    process(CLK)
        variable e_u : UNSIGNED(14 DOWNTO 0);
    begin
        if rising_edge(CLK) then
            e_u := UNSIGNED(E);
            if e_u = 0 then
                counter <= (OTHERS => '0');
                c_reg <= '0';
            else
                if counter = e_u - 1 then
                    counter <= (OTHERS => '0');
                    c_reg <= NOT c_reg;
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process;

    C <= c_reg;
END A_CLK;