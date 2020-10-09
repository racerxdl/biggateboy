module top (
  input  wire clk,
  output wire led
);

// FPGA 25MHz

reg [15:0] dividerMillis = 0;
wire clk1ms = dividerMillis > 12250;

// 1ms clock generator
always @(posedge clk)
begin
  if (dividerMillis > 25000)
    dividerMillis <= 0;
  else
    dividerMillis <= dividerMillis + 1;
end

// PWM Generator

reg [7:0] brightness = 0;
reg [7:0] pwm = 0;

reg ledVal = 0;

always @(posedge clk) // 25MHz / 32
begin
  pwm <= pwm + 1;
  ledVal <= pwm > brightness;
end

reg [3:0] slowerSpeed = 0;

// Brightness Changer
always @(posedge clk1ms)
begin
  slowerSpeed <= slowerSpeed + 1;
  if (slowerSpeed > 4)
    brightness <= brightness + 1;
end

assign led = ledVal;

endmodule