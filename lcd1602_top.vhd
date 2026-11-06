library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- LCD1602 驱动，现在使用KEY控制歌曲名称显示
entity lcd1602_top is
    port (
        clk      : in  std_logic;                             -- 20MHz 时钟
        rst      : in  std_logic;                             -- 高电平复位
        lcd_rs   : out std_logic;                             -- RS
        lcd_rw   : out std_logic;                             -- RW (写入时为 '0')
        lcd_en   : out std_logic;                             -- EN
        lcd_data : out std_logic_vector(7 downto 0);          -- D7..D0
        song_sel : in  std_logic_vector(1 downto 0)           -- 现在连接到KEY: 00->LIANG, 01->SHI, 10->YIN, 11->YI
    );
end entity;

architecture rtl of lcd1602_top is

    constant DELAY_15MS  : unsigned(25 downto 0) := to_unsigned(300000, 26); -- 15ms @20MHz
    constant DELAY_4MS   : unsigned(25 downto 0) := to_unsigned(80000, 26);  -- 4ms
    constant DELAY_100US : unsigned(25 downto 0) := to_unsigned(2000, 26);   -- 100us
    constant DELAY_40US  : unsigned(25 downto 0) := to_unsigned(800, 26);    -- 40us

    type lcd_state_type is (IDLE, S0, S1, S2, S3, S4, ADDR1, WR1, STOP);
    signal lcd_state : lcd_state_type := IDLE;

    -- 延时子模块信号
    signal delay_cnt     : unsigned(25 downto 0) := (others => '0');
    signal delay_running : std_logic := '0';
    signal delay_start   : std_logic := '0';
    signal delay_en      : std_logic := '0';
    signal delay_target  : unsigned(25 downto 0) := (others => '0');

    -- LCD 输出寄存器
    signal rs_reg    : std_logic := '0';
    signal rw_reg    : std_logic := '0';
    signal en_reg    : std_logic := '0';
    signal data_reg  : std_logic_vector(7 downto 0) := (others => '0');

    -- 数据显示控制
    signal data_cnt      : integer range 0 to 31 := 0;
    signal data_display  : std_logic_vector(7 downto 0) := (others => '0');

    -- song_sel change detection
    signal prev_sel : std_logic_vector(1 downto 0) := (others => '0');
    signal update_req : std_logic := '1';

begin

    lcd_rs   <= rs_reg;
    lcd_rw   <= rw_reg;
    lcd_en   <= en_reg;
    lcd_data <= data_reg;

    ----------------------------------------------------------------
    -- 延时子模块
    ----------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            delay_cnt     <= (others => '0');
            delay_running <= '0';
            delay_en      <= '0';
        elsif rising_edge(clk) then
            if delay_running = '0' then
                if delay_start = '1' then
                    delay_cnt     <= delay_target;
                    delay_running <= '1';
                    delay_en      <= '0';
                else
                    delay_en <= '0';
                end if;
            else
                if delay_cnt = 0 then
                    delay_running <= '0';
                    delay_en      <= '1';
                else
                    delay_cnt <= delay_cnt - 1;
                    delay_en  <= '0';
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- data mapping for song_sel (now controlled by KEY)
    ----------------------------------------------------------------
    process(data_cnt, song_sel)
    begin
        case song_sel is
            when "00" => -- LIANG (梁祝)
                case data_cnt is
                    when 0 => data_display <= x"4C"; -- 'L'
                    when 1 => data_display <= x"49"; -- 'I'
                    when 2 => data_display <= x"41"; -- 'A'
                    when 3 => data_display <= x"4E"; -- 'N'
                    when 4 => data_display <= x"47"; -- 'G'
                    when others => data_display <= x"20";
                end case;
            when "01" => -- SHI (世上只有妈妈好)
                case data_cnt is
                    when 0 => data_display <= x"53"; -- 'S'
                    when 1 => data_display <= x"48"; -- 'H'
                    when 2 => data_display <= x"49"; -- 'I'
                    when others => data_display <= x"20";
                end case;
            when "10" => -- YIN (隐形的翅膀)
                case data_cnt is
                    when 0 => data_display <= x"59"; -- 'Y'
                    when 1 => data_display <= x"49"; -- 'I'
                    when 2 => data_display <= x"4E"; -- 'N'
                    when others => data_display <= x"20";
                end case;
            when others => -- "11" -> YI (一剪梅)
                case data_cnt is
                    when 0 => data_display <= x"59"; -- 'Y'
                    when 1 => data_display <= x"49"; -- 'I'
                    when others => data_display <= x"20";
                end case;
        end case;
    end process;

    ----------------------------------------------------------------
    -- detect song_sel change (now from KEY)
    ----------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            prev_sel <= (others => '0');
            update_req <= '1';
        elsif rising_edge(clk) then
            if song_sel /= prev_sel then
                prev_sel <= song_sel;
                update_req <= '1';
            else
                if lcd_state = STOP then
                    update_req <= '0';
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- LCD 主状态机（初始化 + 写入第一行）
    ----------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            rs_reg    <= '0';
            rw_reg    <= '0';
            en_reg    <= '0';
            data_reg  <= (others => '0');
            data_cnt  <= 0;
            lcd_state <= IDLE;
            delay_start <= '0';
            delay_target <= (others => '0');
        elsif rising_edge(clk) then

            if delay_en = '1' then
                null;
            end if;

            case lcd_state is
                when IDLE =>
                    en_reg <= '0';
                    delay_target <= DELAY_15MS;
                    delay_start  <= '1';
                    if delay_en = '1' then
                        delay_start <= '0';
                        lcd_state   <= S0;
                    end if;

                when S0 => -- 功能设置 0x38
                    rs_reg   <= '0';
                    rw_reg   <= '0';
                    en_reg   <= '1';
                    data_reg <= x"38";
                    delay_target <= DELAY_100US;
                    delay_start  <= '1';
                    if delay_en = '1' then
                        delay_start <= '0';
                        en_reg      <= '0';
                        lcd_state   <= S1;
                    end if;

                when S1 => -- 显示关闭 0x08
                    rs_reg   <= '0';
                    rw_reg   <= '0';
                    en_reg   <= '1';
                    data_reg <= x"08";
                    delay_target <= DELAY_100US;
                    delay_start  <= '1';
                    if delay_en = '1' then
                        delay_start <= '0';
                        en_reg      <= '0';
                        lcd_state <= S2;
                    end if;

                when S2 => -- 清屏 0x01
                    rs_reg   <= '0';
                    rw_reg   <= '0';
                    en_reg   <= '1';
                    data_reg <= x"01";
                    delay_target <= DELAY_4MS;
                    delay_start  <= '1';
                    if delay_en = '1' then
                        delay_start <= '0';
                        en_reg      <= '0';
                        lcd_state <= S3;
                    end if;

                when S3 => -- 输入模式 0x06
                    rs_reg   <= '0';
                    rw_reg   <= '0';
                    en_reg   <= '1';
                    data_reg <= x"06";
                    delay_target <= DELAY_100US;
                    delay_start  <= '1';
                    if delay_en = '1' then
                        delay_start <= '0';
                        en_reg      <= '0';
                        lcd_state <= S4;
                    end if;

                when S4 => -- 显示开启 0x0C
                    rs_reg   <= '0';
                    rw_reg   <= '0';
                    en_reg   <= '1';
                    data_reg <= x"0C";
                    delay_target <= DELAY_100US;
                    delay_start  <= '1';
                    if delay_en = '1' then
                        delay_start <= '0';
                        en_reg      <= '0';
                        lcd_state   <= ADDR1;
                    end if;

                when ADDR1 => -- 设置第一行起始地址 0x80
                    rs_reg   <= '0';
                    rw_reg   <= '0';
                    en_reg   <= '1';
                    data_reg <= x"80";
                    delay_target <= DELAY_100US;
                    delay_start  <= '1';
                    if delay_en = '1' then
                        delay_start <= '0';
                        en_reg      <= '0';
                        data_cnt    <= 0;
                        lcd_state   <= WR1;
                    end if;

                when WR1 => -- 写第一行字符（写 5 个位置）
                    rs_reg   <= '1';
                    rw_reg   <= '0';
                    en_reg   <= '1';
                    data_reg <= data_display;
                    delay_target <= DELAY_40US;
                    delay_start  <= '1';
                    if delay_en = '1' then
                        delay_start <= '0';
                        en_reg      <= '0';
                        if data_cnt = 4 then
                            data_cnt  <= 0;
                            lcd_state <= STOP;
                        else
                            data_cnt <= data_cnt + 1;
                        end if;
                    end if;

                when STOP =>
                    rs_reg   <= '0';
                    rw_reg   <= '0';
                    en_reg   <= '0';
                    data_reg <= (others => '0');
                    delay_start <= '0';
                    if update_req = '1' then
                        lcd_state <= ADDR1;
                    else
                        lcd_state <= STOP;
                    end if;

                when others =>
                    lcd_state <= IDLE;
            end case;
        end if;
    end process;

end architecture;