// All I/O Regs are prefixed by 16'hFF00

parameter IOREG_JOYP        = 7'h00; // Joypad (R/W)
parameter IOREG_SB          = 7'h01; // Serial transfer data (R/W)
parameter IOREG_SC          = 7'h02; // Serial Transfer Control (R/W)

parameter IOREG_DIV         = 7'h04; // Divider Register (R/W)
parameter IOREG_TIMA        = 7'h05; // Timer counter (R/W)
parameter IOREG_TMA         = 7'h06; // Timer Modulo (R/W)
parameter IOREG_TAC         = 7'h07; // Timer Control (R/W)

parameter IOREG_IF          = 7'h0F; // Interrupt Flag (R/W) (1=Request)

parameter IOREG_NR10        = 7'h10; // Channel 1 Sweep register (R/W)
parameter IOREG_NR11        = 7'h11; // Channel 1 Sound length/Wave pattern duty (R/W)
parameter IOREG_NR12        = 7'h12; // Channel 1 Volume Envelope (R/W)
parameter IOREG_NR13        = 7'h13; // Channel 1 Frequency lo (Write Only)
parameter IOREG_NR14        = 7'h14; // Channel 1 Frequency hi (R/W)

parameter IOREG_NR21        = 7'h16; // Channel 2 Sound Length/Wave Pattern Duty (R/W)
parameter IOREG_NR22        = 7'h17; // Channel 2 Volume Envelope (R/W)
parameter IOREG_NR23        = 7'h18; // Channel 2 Frequency lo data (W)
parameter IOREG_NR24        = 7'h19; // Channel 2 Frequency hi data (R/W)

parameter IOREG_NR30        = 7'h1A; // Channel 3 Sound on/off (R/W)
parameter IOREG_NR31        = 7'h1B; // Channel 3 Sound Length
parameter IOREG_NR32        = 7'h1C; // Channel 3 Select output level (R/W)
parameter IOREG_NR33        = 7'h1D; // Channel 3 Frequency's lower data (W)
parameter IOREG_NR34        = 7'h1E; // Channel 3 Frequency's higher data (R/W)

parameter IOREG_NR41        = 7'h20; // Channel 4 Sound Length (R/W)
parameter IOREG_NR42        = 7'h21; // Channel 4 Volume Envelope (R/W)
parameter IOREG_NR43        = 7'h22; // Channel 4 Polynomial Counter (R/W)
parameter IOREG_NR44        = 7'h23; // Channel 4 Counter/consecutive; Inital (R/W)
parameter IOREG_NR50        = 7'h24; // Channel control / ON-OFF / Volume (R/W)
parameter IOREG_NR51        = 7'h25; // Selection of Sound output terminal (R/W)
parameter IOREG_NR52        = 7'h26; // Sound on/off

parameter IOREG_WAVSTART    = 7'h30; // Wave Pattern RAM Start
parameter IOREG_WAVEND      = 7'h3F; // Wave Pattern RAM End
parameter IOREG_LCDCONTROL  = 7'h40; // LCDC - LCD Control (R/W)
parameter IOREG_LCDSTAT     = 7'h41; // STAT - LCDC Status (R/W)
parameter IOREG_SCROLLY     = 7'h42; // SCY - Scroll Y (R/W)
parameter IOREG_SCROLLX     = 7'h43; // SCX - Scroll X (R/W)
parameter IOREG_LY          = 7'h44; // LY - LCDC Y-Coordinate (R)
parameter IOREG_LYC         = 7'h45; // LYC - LY Compare (R/W)
parameter IOREG_DMA         = 7'h46; // DMA Transfer and Start Address (R/W)
parameter IOREG_BGP         = 7'h47; // BGP - BG Palette Data (R/W) - Non CGB Mode Only
parameter IOREG_OBP0        = 7'h48; // Object Palette 0 Data (R/W) - Non CGB Mode Only
parameter IOREG_OBP1        = 7'h49; // Object Palette 1 Data (R/W) - Non CGB Mode Only
parameter IOREG_WY          = 7'h4A; // WY - Window Y Position (R/W)
parameter IOREG_WX          = 7'h4B; // WX - Window X Position minus 7 (R/W)

parameter IOREG_KEY1        = 7'h4D; // CGB Mode Only - Prepare Speed Switch

parameter IOREG_VRAMBANK    = 7'h4F; // VBK - CGB Mode Only - VRAM Bank (R/W)
parameter IOREG_BIOSENABLED = 7'h50; // If Gameboy bios is mapped into lower 256 bytes. 0 == enabled
parameter IOREG_HDMA1       = 7'h51; // HDMA1 - CGB Mode Only - New DMA Source, High
parameter IOREG_HDMA2       = 7'h52; // HDMA2 - CGB Mode Only - New DMA Source, Low
parameter IOREG_HDMA3       = 7'h53; // HDMA3 - CGB Mode Only - New DMA Destination, High
parameter IOREG_HDMA4       = 7'h54; // HDMA4 - CGB Mode Only - New DMA Destination, Low
parameter IOREG_HDMA5       = 7'h55; // HDMA5 - CGB Mode Only - New DMA Length/Mode/Start
parameter IOREG_RP          = 7'h56; // CGB Mode Only - Infrared Communications Port

parameter IOREG_BGPI        = 7'h68; // CGB Mode Only - Background Palette Index
parameter IOREG_BGPD        = 7'h69; // CGB Mode Only - Background Palette Data
parameter IOREG_OBPI        = 7'h6A; // CGB Mode Only - Sprite Palette Index
parameter IOREG_OBPD        = 7'h6B; // CGB Mode Only - Sprite Palette Data

parameter IOREG_SVBK        = 7'h70; // CGB Mode Only - WRAM Bank

parameter IOREG_PCM12       = 7'h76; // PCM amplitudes 1 & 2 (Read Only)
parameter IOREG_PCM34       = 7'h77; // PCM amplitudes 1 & 2 (Read Only)

parameter IOREG_IE          = 7'hFF; // Interrupt Enable (R/W) (1=Enable)