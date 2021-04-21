module ClockDivider (
  input       sclk,
  input       rst,
  input       cgbMode,
  output      gclk
);


parameter SYSTEM_CLOCK    = 25000000; // 25MHz
parameter gameboyClock    = 4194304;  // 4.19 MHz

// These numbers are aproximated
localparam dividerWidth    = 32;
localparam dividerMax      = (SYSTEM_CLOCK / gameboyClock);
localparam cgbDividerMax   = dividerMax / 2;

initial begin
  `ifdef SIMULATION
    $display("Input Frequency: %d", SYSTEM_CLOCK);
    $display("DividerMax: %d", dividerMax);
    $display("CGB Mode DividerMax: %d", cgbDividerMax);
  `endif
end

reg  [dividerWidth-1:0] divider = 0;

wire genClk = cgbMode ? divider <=  cgbDividerMax / 2 : divider <=  dividerMax / 2;
wire max    = cgbMode ? divider == cgbDividerMax : divider == dividerMax;

always @(posedge sclk)
begin
  if(rst | max)
    divider <= 0;
  else
    divider <= divider + 1;
end

assign gclk = genClk;

endmodule
