library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY MUSIC IS
PORT(
    CLK      : IN  STD_LOGIC;                                  -- 20MHz 系统时钟
    CO       : OUT STD_LOGIC;
    KEY      : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);               -- 现在用KEY控制歌曲名称
    AD       : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    KJ       : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);               -- 拨码选择（现在只控制播放速度）
    seg      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    seg1     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    -- LCD1602 接口（映射到开发板引脚）
    lcd_rs   : OUT STD_LOGIC;
    lcd_rw   : OUT STD_LOGIC;
    lcd_en   : OUT STD_LOGIC;
    lcd_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    -- 复位按键（板上按键通常为 active-low，连接到地按下）
    BTN_RST_N : IN STD_LOGIC
);
END MUSIC;

ARCHITECTURE A_MUSIC OF MUSIC IS

    SIGNAL S1:STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL S2:STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL S3:STD_LOGIC_VECTOR(8 DOWNTO 0);
    SIGNAL S4:STD_LOGIC_VECTOR(14 DOWNTO 0);
    SIGNAL s5:STD_LOGIC;
    SIGNAL CLK2:STD_LOGIC;

    -- POR 产生
    SIGNAL por_cnt : UNSIGNED(17 DOWNTO 0) := (OTHERS => '0');
    CONSTANT POR_MAX : UNSIGNED(17 DOWNTO 0) := TO_UNSIGNED(200000, 18); -- 10ms @20MHz
    SIGNAL por_active : STD_LOGIC := '1';

    -- 按键去抖输出
    SIGNAL btn_raw : STD_LOGIC;
    SIGNAL btn_db  : STD_LOGIC;

    -- 最终复位（高电平有效）
    SIGNAL rst_lcd : STD_LOGIC;

    -- Component 声明
    COMPONENT M_582 IS
    PORT(CLK:IN STD_LOGIC; seg:out std_logic_vector(7 downto 0); CO1:OUT std_logic_vector(9 downto 0); K:IN std_logic_vector(1 downto 0));
    END COMPONENT;

    COMPONENT S_ROM IS
        PORT(ADDRESS:IN STD_LOGIC_VECTOR(9 DOWNTO 0); CLOCK:IN STD_LOGIC; Q:OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
    END COMPONENT;

    COMPONENT FP IS
    PORT(D:IN STD_LOGIC_VECTOR(7 DOWNTO 0); E:OUT STD_LOGIC_VECTOR(8 DOWNTO 0); CD:OUT STD_LOGIC_VECTOR(9 DOWNTO 0));
    END COMPONENT;

    COMPONENT SKFP IS
    PORT(CLK:IN STD_LOGIC; E:IN STD_LOGIC_VECTOR(8 DOWNTO 0); C:OUT STD_LOGIC);
    END COMPONENT;

    COMPONENT CLK_2 IS
    PORT(CLK:IN STD_LOGIC; E:IN STD_LOGIC_VECTOR(14 DOWNTO 0); C:OUT STD_LOGIC);
    END COMPONENT;

    COMPONENT DIV IS
    PORT(CLK: IN STD_LOGIC; DIV_CLK: OUT STD_LOGIC);
    END COMPONENT;

    COMPONENT lcd1602_top IS
        PORT (clk: IN STD_LOGIC; rst: IN STD_LOGIC; lcd_rs: OUT STD_LOGIC; lcd_rw: OUT STD_LOGIC; lcd_en: OUT STD_LOGIC; lcd_data: OUT STD_LOGIC_VECTOR(7 DOWNTO 0); song_sel: IN STD_LOGIC_VECTOR(1 DOWNTO 0));
    END COMPONENT;

    COMPONENT Debounce is
        port(clk: in std_logic; btn_in: in std_logic; btn_db: out std_logic);
    END COMPONENT;

BEGIN

    -- POR：上电保持一段时间
    POR_PROC: process(CLK)
    begin
        if rising_edge(CLK) then
            if por_cnt < POR_MAX then
                por_cnt <= por_cnt + 1;
                por_active <= '1';
            else
                por_active <= '0';
            end if;
        end if;
    end process;

    -- 物理按键 (active-low) 取反为高表示按下传入去抖模块
    btn_raw <= not BTN_RST_N;

    UDB: Debounce port map (clk => CLK, btn_in => btn_raw, btn_db => btn_db);

    -- 最终复位：POR 或 按键按下 任一为高
    rst_lcd <= por_active or btn_db;

    -- KJ -> S4 / seg1 映射（保留逻辑，只控制播放速度）
    process(KJ, CLK)
    begin
        if rising_edge(CLK) then
            if KJ = "00" then
                S4 <= "110000110101000";
                seg1 <= "01100000";
            elsif KJ = "01" then
                S4 <= "011000011010100";
                seg1 <= "11010011";
            elsif KJ = "10" then
                S4 <= "001100001101010";
                seg1 <= "11110010";
            else
                S4 <= "000110000110101";
                seg1 <= "01100110";
            end if;
        end if;
    end process;

    U1: M_582 PORT MAP (CLK => CLK2, seg => seg, CO1 => S1, K => KEY);  -- KEY控制歌曲选择
    U2: S_ROM PORT MAP (ADDRESS => S1, CLOCK => CLK2, Q => S2);
    U3: FP    PORT MAP (D => S2, E => S3, CD => AD);
    U4: SKFP  PORT MAP (CLK => s5, E => S3, C => CO);
    U5: CLK_2 PORT MAP (CLK => s5, E => S4, C => CLK2);
    U6: DIV   PORT MAP (CLK => CLK, DIV_CLK => s5);

    -- LCD 实例化，现在使用KEY控制歌曲名称显示
    U7: lcd1602_top PORT MAP (
        clk => CLK,
        rst => rst_lcd,
        lcd_rs => lcd_rs,
        lcd_rw => lcd_rw,
        lcd_en => lcd_en,
        lcd_data => lcd_data,
        song_sel => KEY  -- 改为使用KEY控制歌曲名称
    );

END A_MUSIC;