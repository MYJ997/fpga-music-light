library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY DIV IS
    PORT(
        CLK     : IN STD_LOGIC;
        DIV_CLK : OUT STD_LOGIC
    );
END DIV;

ARCHITECTURE A_DIV OF DIV IS
    -- 20MHz / 100kHz = 200 -> half-period counter to toggle -> use 100 count for half period
    SIGNAL cnt : INTEGER RANGE 0 TO 99 := 0;
    SIGNAL out_reg : STD_LOGIC := '0';
BEGIN
    PROCESS(CLK)
    BEGIN
        if rising_edge(CLK) then
            if cnt = 99 then
                cnt <= 0;
                out_reg <= NOT out_reg;
            else
                cnt <= cnt + 1;
            end if;
        end if;
    END PROCESS;

    DIV_CLK <= out_reg;
END A_DIV;