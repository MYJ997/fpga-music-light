library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY M_582 IS
PORT(
    CLK : IN STD_LOGIC;
    seg : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    CO1 : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    K   : IN STD_LOGIC_VECTOR(1 DOWNTO 0)
);
END M_582;

ARCHITECTURE A_M582 OF M_582 IS
    SIGNAL q1 : UNSIGNED(9 DOWNTO 0) := (OTHERS => '0');  -- 0..138
    SIGNAL q2 : UNSIGNED(9 DOWNTO 0) := TO_UNSIGNED(139, 10);
    SIGNAL q3 : UNSIGNED(9 DOWNTO 0) := TO_UNSIGNED(267, 10);
    SIGNAL q4 : UNSIGNED(9 DOWNTO 0) := TO_UNSIGNED(451, 10);
    SIGNAL qq : UNSIGNED(9 DOWNTO 0) := (OTHERS => '0');

    CONSTANT END1 : UNSIGNED(9 DOWNTO 0) := TO_UNSIGNED(138, 10);
    CONSTANT START2 : UNSIGNED(9 DOWNTO 0) := TO_UNSIGNED(139, 10);
    CONSTANT END2 : UNSIGNED(9 DOWNTO 0) := TO_UNSIGNED(266, 10);
    CONSTANT START3 : UNSIGNED(9 DOWNTO 0) := TO_UNSIGNED(267, 10);
    CONSTANT END3 : UNSIGNED(9 DOWNTO 0) := TO_UNSIGNED(450, 10);
    CONSTANT START4 : UNSIGNED(9 DOWNTO 0) := TO_UNSIGNED(451, 10);
    CONSTANT END4 : UNSIGNED(9 DOWNTO 0) := TO_UNSIGNED(582, 10);
BEGIN
    PROCESS(CLK)
    BEGIN
        if rising_edge(CLK) then
            case K is
                when "00" =>
                    qq <= q1;
                    seg <= "00000110";
                    if q1 = END1 then
                        q1 <= (OTHERS => '0');
                    else
                        q1 <= q1 + 1;
                    end if;
                when "01" =>
                    qq <= q2;
                    seg <= "01011011";
                    if q2 = END2 then
                        q2 <= START2;
                    else
                        q2 <= q2 + 1;
                    end if;
                when "10" =>
                    qq <= q3;
                    seg <= "01001111";
                    if q3 = END3 then
                        q3 <= START3;
                    else
                        q3 <= q3 + 1;
                    end if;
                when others =>
                    qq <= q4;
                    seg <= "01100110";
                    if q4 = END4 then
                        q4 <= START4;
                    else
                        q4 <= q4 + 1;
                    end if;
            end case;
        end if;
    end process;

    CO1 <= STD_LOGIC_VECTOR(qq);

END A_M582;