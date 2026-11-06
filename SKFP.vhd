library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY SKFP IS
PORT(
    CLK : IN STD_LOGIC;
    E   : IN STD_LOGIC_VECTOR(8 DOWNTO 0); -- 分频参数
    C   : OUT STD_LOGIC
);
END SKFP;

ARCHITECTURE A_SKFP OF SKFP IS
    SIGNAL cnt : UNSIGNED(8 DOWNTO 0) := (OTHERS => '0');
    SIGNAL out_reg : STD_LOGIC := '0';
BEGIN
    process(CLK)
        variable e_u : UNSIGNED(8 DOWNTO 0);
    begin
        if rising_edge(CLK) then
            e_u := UNSIGNED(E);
            if e_u = 0 then
                cnt <= (OTHERS => '0');
                out_reg <= '0';
            else
                if cnt = e_u - 1 then
                    cnt <= (OTHERS => '0');
                    out_reg <= NOT out_reg;
                else
                    cnt <= cnt + 1;
                end if;
            end if;
        end if;
    end process;

    C <= out_reg;
END A_SKFP;