module CPU (
  input  wire         clk,          // 4MHz clock
  input  wire         reset,
  output reg  [15:0]  memAddress,
  input  wire [7:0]   memDataR,
  output reg  [7:0]   memDataW,
  output reg          RW            // R/W (0 == Read, 1 == Write)
);

// Synchronous ALU
reg   [15:0]    AluX      = 0;
reg   [15:0]    AluY      = 0;
reg   [4:0]     AluOp     = 0;
reg             AluEnable = 0;
reg             AluWriteA = 0;
    
wire  [15:0]    RegA;
wire  [7:0]     RegF;

ALUSync alu(clk, reset, AluOp, AluX, AluY, AluEnable, AluWriteA, RegA, RegF);

// Register Bank
reg   [7:0]     RegBankIn;
wire  [7:0]     RegBankOut;
wire  [15:0]    RegBankOut16;
reg   [2:0]     RegNum;
reg             RegWriteEnable;

RegisterBank regBank(clk, reset, RegBankIn, RegBankOut, RegBankOut16, RegNum, RegWriteEnable);

// Program Counter
reg  [15:0]   PCDataIn = 0;
wire [15:0]   PCDataOut;
reg           PCWriteEnable = 0; // 1 => WRITE, 0 => READ
reg           PCCountEnable = 0; // 1 => COUNT UP, 0 => STOPPED
reg           PCWriteAddTo  = 0; // 1 => Add to PC, 0 => Set to PC

// Our device under test
ProgramCounter dut(clk, reset, PCDataIn, PCDataOut, PCWriteEnable, PCWriteAddTo, PCCountEnable);

always @(posedge clk)
begin
  if (reset)
  begin
    // ALU Reset
    AluX            <= 0;
    AluY            <= 0;
    AluOp           <= 0;
    AluEnable       <= 0;

    // Register Bank Reset
    RegBankIn       <= 0;
    RegNum          <= 0;
    RegWriteEnable  <= 0;

    // Bus Reset
    memDataW        <= 0;
    RW              <= 0;
    memAddress      <= 0;

    // Program Counter
    PCDataIn        <= 0;
    PCCountEnable   <= 0;
    PCWriteAddTo    <= 0;
  end
end

endmodule