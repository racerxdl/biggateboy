module SerialTX (
  input wire clk,  // 25MHz
  input wire send, // Send Flag
  input [7:0] data,

  output wire busy, // Busy Flag
  output wire tx
);

parameter inputFrequency  = 25000000;
parameter baudRate        = 115200;
parameter baudGenWidth    = 16;
parameter baudMax         = (inputFrequency / baudRate);


reg  [baudGenWidth-1:0] baudDivider = 0;

wire baudClock = baudDivider == baudMax;

always @(posedge clk)
begin
  if (baudClock)
    baudDivider <= 0;
  else
    baudDivider <= baudDivider + 1;
end

localparam
  S_READY    = 4'b0000, // => Ready
  S_STARTED  = 4'b0001, // => Started (busy)
  S_STOP0    = 4'b0011, // => Stop bit 1
  S_STOP1    = 4'b0100, // => Stop bit 2
  S_START    = 4'b0101, // => Start Bit
  S_BIT0     = 4'b1000, // => Bit 0
  S_BIT1     = 4'b1001, // => Bit 1
  S_BIT2     = 4'b1010, // => Bit 2
  S_BIT3     = 4'b1011, // => Bit 3
  S_BIT4     = 4'b1100, // => Bit 4
  S_BIT5     = 4'b1101, // => Bit 5
  S_BIT6     = 4'b1110, // => Bit 6
  S_BIT7     = 4'b1111; // => Bit 7

reg [3:0] state = S_READY;

wire ready = (state == S_READY);
assign busy = ~ready;

reg [7:0] txData;

// Data Save
always @(posedge clk)
begin
  if (send & ready)
  begin
    txData <= data;
  end
end

// State Machine Change
always @(posedge clk)
begin
  if (send && state == S_READY)
  begin
    state <= S_STARTED;
  end
  else if (baudClock)
  begin
    case(state)
      S_STARTED:  state <= S_START;
      S_START:    state <= S_BIT0;
      S_BIT0:     state <= S_BIT1;
      S_BIT1:     state <= S_BIT2;
      S_BIT2:     state <= S_BIT3;
      S_BIT3:     state <= S_BIT4;
      S_BIT4:     state <= S_BIT5;
      S_BIT5:     state <= S_BIT6;
      S_BIT6:     state <= S_BIT7;
      S_BIT7:     state <= S_STOP0;
      S_STOP0:    state <= S_STOP1;
      S_STOP1:    state <= S_READY;
      default:    state <= S_READY;
    endcase
  end
end

reg bitOut;

always @(*)
begin
  if (state == S_START)
    bitOut <= 0; // Start bit
  else if (state == S_STOP0 || state == S_STOP1 || state == S_READY || state == S_STARTED)
    bitOut <= 1;
  else
    bitOut <= txData[state[2:0]];
end

assign tx = bitOut;

endmodule
