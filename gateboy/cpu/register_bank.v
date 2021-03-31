module RegisterBank (
  input   wire          clk,
  input   wire          reset,
  input         [7:0]   dataIn,
  output  wire  [7:0]   dataOut,
  output  wire  [15:0]  dataOut16,
  output  wire  [15:0]  stackPointer,
  input         [2:0]   regNum,
  input                 writeEnable     // 1 => WRITE, 0 => READ
);

// B C D E H L S P W Z
reg [7:0] registers [0:9];

initial begin
  for ( i = 0; i < 10; i=i+1)
  begin
    registers[i] = 0;
  end
end

integer i;

always @(posedge clk)
begin
  if (!reset && writeEnable) registers[regNum] <= dataIn;
end

assign dataOut = registers[regNum];

wire [2:0] upperReg = {regNum[2:1], 1'b1};
wire [2:0] lowerReg = {regNum[2:1], 1'b0};

assign dataOut16 = {registers[lowerReg], registers[upperReg]};
assign stackPointer = {registers[7], registers[6]};

// Only for simulation expose the registers
generate
  genvar idx;
  for(idx = 0; idx < 10; idx = idx+1) begin: register
    wire [7:0] tmp;
    assign tmp = registers[idx];
  end
endgenerate

endmodule