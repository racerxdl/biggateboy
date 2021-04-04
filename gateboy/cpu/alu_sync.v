module ALUSync (
  input wire          clk,
  input wire          reset,
  input wire  [7:0]   op,         // Operation
  input wire  [15:0]  X,          // First Operand
  input wire  [15:0]  Y,          // Second Operand
  input wire          enable,
  input wire          writeA,

  output reg  [15:0]  A,
  output wire [15:0]  O,
  output reg  [7:0]   F
);

wire [3:0]  OutF;

// Our device under test
ALU alu(op, X, Y, F[3:0], OutF, O);

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
    else if (writeA) A <= X;
  end
end

// Only for simulation expose the registers
generate
  genvar idx;
  for(idx = 0; idx < 4; idx = idx+1) begin: register
    wire tmp;
    assign tmp = F[idx];
  end
endgenerate

endmodule