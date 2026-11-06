# FPGA 音乐彩灯（VHDL）

基于 Altera Cyclone II（EP2C5T144C8）的数字音乐播放与彩灯控制设计，使用纯 VHDL 实现。

系统从片上 ROM 读取乐谱数据，按音符查表得到分频系数并产生音调输出，同时用数码管显示当前歌曲与速度模式，用 LCD1602 显示歌曲名称。按键切换歌曲，拨码开关切换播放速度。

## 功能

- 内置 4 首乐曲，`KEY[1:0]` 切换
- `KJ[1:0]` 选择 4 档播放速度
- 音调输出到蜂鸣器（`CO`）
- 数码管显示歌曲编号与速度模式
- LCD1602 显示当前歌曲名称
- 按键同步与 10 ms 消抖

## 模块说明

| 文件 | 说明 |
| --- | --- |
| `MUSIC.vhd` | 顶层，例化并连接各子模块 |
| `DIV.vhd` | 系统时钟分频，20 MHz 分频出 100 kHz |
| `M_582.vhd` | 乐谱地址计数器，按按键在 4 首乐曲间切换 |
| `S_ROM.vhd` | 583×8 单端口 ROM，由 Quartus MegaWizard 生成，初始化文件为 `DATA.mif` |
| `FP.vhd` | 音符到分频系数、显示码的查找表 |
| `SKFP.vhd` | 按分频系数产生音调方波，并调节占空比 |
| `CLK_2.vhd` | 节拍时钟分频，由 `KJ` 选择速度 |
| `Debounce.vhd` | 按键两级同步与计数消抖 |
| `lcd1602_top.vhd` | LCD1602 初始化与歌名显示状态机 |

## 引脚分配

器件：`EP2C5T144C8`，时钟 20 MHz。

| 信号 | 引脚 | 说明 |
| --- | --- | --- |
| `CLK` | PIN_17 | 系统时钟 |
| `CO` | PIN_93 | 音调输出 |
| `KEY[1:0]` | PIN_91 / PIN_90 | 歌曲选择 |
| `KJ[1:0]` | PIN_89 / PIN_88 | 速度选择 |
| `AD[9:0]` | PIN_120 ~ PIN_136 | 乐谱地址输出 |
| `seg[7:0]` | PIN_24 ~ PIN_30 | 数码管段码 |
| `seg1[7:0]` | PIN_31 ~ PIN_45 | 数码管位选 |
| `lcd_rs` / `lcd_rw` / `lcd_en` | PIN_51 / PIN_52 / PIN_53 | LCD1602 控制 |
| `lcd_data[7:0]` | PIN_55 ~ PIN_65 | LCD1602 数据 |
| `BTN_RST_N` | PIN_118 | 复位按键，低有效 |

完整约束见 `MUSIC.qsf`。

## 目录结构

```
.
├── MUSIC.vhd            顶层
├── DIV.vhd              时钟分频
├── CLK_2.vhd            节拍分频
├── M_582.vhd            乐曲切换
├── FP.vhd               音符查找表
├── SKFP.vhd             音调发生
├── Debounce.vhd         按键消抖
├── lcd1602_top.vhd      LCD1602 驱动
├── S_ROM.vhd            ROM（MegaWizard 生成）
├── DATA.mif             乐谱数据
├── S_ROM.qip            ROM IP 声明
├── MUSIC.qpf / MUSIC.qsf    Quartus 工程与约束
└── sim/                 功能仿真波形文件
```

## 构建

1. 用 Quartus II 13.0 打开 `MUSIC.qpf`。
2. 确认器件为 `EP2C5T144C8`。
3. 编译后下载生成的 SOF/POF 文件。

## 仿真

`sim/` 下保存了 9 个 Vector Waveform 文件，用于 Quartus 功能仿真（Simulation Mode 选择 Functional）。仿真时钟前需在波形文件中确认信号与当前顶层端口一致。

## 说明

- `S_ROM.vhd`、`DATA.mif`、`S_ROM.qip` 由 Quartus MegaWizard 生成，其版权归 Altera/Intel，随工程保留用于复现 ROM 配置。
