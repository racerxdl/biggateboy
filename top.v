module Gameboy (
  input  wire clk,
  input  wire rst,
  output reg  led
);

`include "ioregisters.v"

reg cgbMode = 0;
reg reset = 1;
wire gameboyClock;

ClockDivider #(
  .SYSTEM_CLOCK(25000000) // 25 MHz
) clkDiv (
  .sclk(clk),
  .rst(reset),
  .cgbMode(cgbMode),
  .gclk(gameboyClock)
);

// reg [3:0] reset_counter = 15; // self-reset
// reg extrst = 1;               // external reset default value (sampled at startup)

// always @(posedge clk)
// begin
//   reset_counter <= reset_counter ? reset_counter-1 : // while(reset_counter--);
//                    extrst!=rst ? 13 : 0; // rst != extrst -> restart counter
//   reset <= reset_counter ? 1 : 0; // while not zero, reset = 1, after that use extrst
//   extrst <= (reset_counter==14) ? rst : extrst; // sample the reset button and store the value when not in reset
// end

always @(*) reset <= rst;

reg [7:0] gbBios      [0:255];
reg [7:0] vRam        [0:16383];
reg [7:0] wRam        [0:32767];
reg [7:0] hRam        [0:127];
reg [7:0] IORegisters [0:127];

reg       vRamBank;
reg [2:0] wRamBank;

// Gameboy
reg   [7:0]   cpuDataIn;
wire  [7:0]   cpuDataOut;
wire  [15:0]  cpuAddress;
wire          cpuBusWriteEnable;     // 1 => WRITE, 0 => READ
wire          cpuHalted;
wire          cpuStopped;

wire  [7:0]   resetInterrupt;
reg   [7:0]   interruptsEnabled;
reg   [7:0]   interruptsFired;

CPU cpu(
  .clk(gameboyClock),
  .reset(reset),
  .memAddress(cpuAddress),
  .memDataR(cpuDataIn),
  .memDataW(cpuDataOut),
  .RW(cpuBusWriteEnable),
  .stopped(cpuStopped),
  .halted(cpuHalted),
  .interruptsEnabled(interruptsEnabled),
  .interruptsFired(interruptsFired),
  .resetInterrupt(resetInterrupt)
);

initial begin
  $readmemh("testdata/gbbios.smem", gbBios);
end

always @(posedge gameboyClock)
begin
  if (reset)
  begin
    cgbMode             <= 0;
    vRamBank            <= 0;
    wRamBank            <= 1;
    cpuDataIn           <= gbBios[0];
    interruptsEnabled   <= 0;
    interruptsFired     <= 0;

    IORegisters[IOREG_BIOSENABLED]  <= 0; // Bios enabled
  end
  else
  begin
    if (cpuAddress <= 16'h3FFF)       // Catrigde / GB Bios
    begin
      if (IORegisters[IOREG_BIOSENABLED] == 0 && cpuAddress <= 256) // BIOS enabled and using
      begin
        cpuDataIn <= gbBios[cpuAddress];
      end
      else
      begin
        cpuDataIn <= 0; // TODO
      end
    end
    else if (cpuAddress <= 16'h7FFF)  // Catridge Bank N
    begin
      cpuDataIn <= 0; // TODO
    end
    else if (cpuAddress <= 16'h9FFF)  // Video Ram
    begin
      cpuDataIn <= 0; // TODO
    end
    else if (cpuAddress <= 16'hBFFF) // External RAM (Catridge)
    begin
      cpuDataIn <= 0; // TODO
    end
    else if (cpuAddress <= 16'hCFFF) // Work Ram Bank 0
    begin
      cpuDataIn <= wRam[cpuAddress[11:0]];
      if (cpuBusWriteEnable) wRam[cpuAddress[11:0]] <= cpuDataOut;
    end
    else if (cpuAddress <= 16'hDFFF) // Work Ram Bank N
    begin
      cpuDataIn <= wRam[{wRamBank, cpuAddress[11:0]}];
      if (cpuBusWriteEnable) wRam[{wRamBank, cpuAddress[11:0]}] <= cpuDataOut;
    end
    else if (cpuAddress <= 16'hFDFF) // ECHO RAM, same as C000~DDFF
    begin
      cpuDataIn <= wRam[cpuAddress[11:0]];
      if (cpuBusWriteEnable) wRam[cpuAddress[11:0]] <= cpuDataOut;
    end
    else if (cpuAddress <= 16'hFE9F) // Sprite attribute table
    begin
      cpuDataIn <= 0; // TODO
    end
    else if (cpuAddress <= 16'hFEFF) // Not used
    begin

    end
    else if (cpuAddress >= 16'hFF00 && cpuAddress <= 16'hFF7F) // I/O Registers
    begin

    end
    else if (cpuAddress == 16'hFFFF) // Interrupts Enabled Register
    begin
      cpuDataIn <= interruptsEnabled;
      if (cpuBusWriteEnable)
        interruptsEnabled <= cpuDataOut;
    end
    else if (cpuAddress >= 16'hFF80 && cpuAddress <= 16'hFFFE) // High Ram
    begin
      cpuDataIn <= hRam[cpuAddress[6:0]];
      if (cpuBusWriteEnable)
        hRam[cpuAddress[6:0]] <= cpuDataOut;
    end
  end
end

endmodule