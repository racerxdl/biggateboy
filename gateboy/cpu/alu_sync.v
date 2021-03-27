module ALUSync (
  input wire          clk,
  input wire          reset,
  input wire  [4:0]   op,     // Operation
  input wire  [15:0]  X,      // First Operand
  input wire  [15:0]  Y,      // Second Operand
  input wire          enable,
  input wire          writeA,

  output reg  [15:0]  A,
  output reg  [7:0]   F
);

wire [7:0]  OutF;
wire [15:0] O;

// Our device under test
ALU alu(op, X, Y, F, OutF, O);

always @(posedge clk)
begin
  if (reset)
  begin
    A <= 0;
    F <= 0;
  end
  else
  begin
    if (enable)
    begin
      if (writeA) A <= O;
      F <= {4'b0000, OutF};
    end
  end
end

endmodule