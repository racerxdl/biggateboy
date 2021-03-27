module ProgramCounter (
  input   wire          clk,
  input   wire          reset,
  input         [15:0]  dataIn,
  output  wire  [15:0]  dataOut,
  input                 writeEnable,    // 1 => WRITE, 0 => READ
  input                 writeAdd,       // 1 => Add dataIn to PC, 0 => Set dataIn to PC
  input                 countEnable     // 1 => COUNT UP, 0 => STOPPED
);

reg [15:0] programCounter;

always @(posedge clk)
begin
  if (reset)
  begin
    programCounter <= 0;
  end
  else if (writeEnable) programCounter <= writeAdd ? programCounter + $signed(dataIn) - 1 : dataIn;
  else if (countEnable) programCounter <= programCounter + 1;
end

assign dataOut = programCounter;

endmodule
