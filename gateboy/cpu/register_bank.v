module RegisterBank (
  input   wire          clk,
  input   wire          reset,
  input         [2:0]   regNum,

  // 8 bit interface
  input         [7:0]   dataIn,
  output  wire  [7:0]   dataOut,
  input                 writeEnable,    // 1 => WRITE, 0 => READ

  // 16 bit interface
  input         [15:0]  dataIn16,
  output  wire  [15:0]  dataOut16,
  input                 writeEnable16  // 1 => WRITE, 0 => READ
);

// B C D E H L W Z
reg [7:0] registers [0:7];

wire [2:0] upperReg = {regNum[2:1], 1'b1};
wire [2:0] lowerReg = {regNum[2:1], 1'b0};

initial begin
  for ( i = 0; i < 8; i=i+1)
  begin
    registers[i] = 0;
  end
end

integer i;

always @(posedge clk)
begin
  if (!reset && writeEnable) registers[regNum] <= dataIn;
  if (!reset && writeEnable16)
  begin
    registers[lowerReg] <= dataIn16[15:8];
    registers[upperReg] <= dataIn16[7:0];
  end
end

assign dataOut = registers[regNum];


assign dataOut16 = {registers[lowerReg], registers[upperReg]};

// Only for simulation expose the registers
generate
  genvar idx;
  for(idx = 0; idx < 8; idx = idx+1) begin: register
    wire [7:0] tmp;
    assign tmp = registers[idx];
  end
endgenerate

endmodule