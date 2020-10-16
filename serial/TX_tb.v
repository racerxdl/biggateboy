`timescale 1 ns/1 ns  // time-unit = 1 ns, precision = 10 ps

module SerialTXTest;
  /* Make a regular pulsing clock. */
  reg clk = 1;
  reg [7:0] data = 0;

  localparam period = 40; // 25Mhz clock
  localparam ms = 1e6;
  localparam us = 1e3;

  localparam inputFrequency  = 25000000;
  localparam baudRate        = 115200;
  localparam baudGenWidth    = 16;
  localparam baudMax         = (inputFrequency / baudRate);

  always #20 clk = !clk;

  wire signal;
  reg send = 0;
  wire busy;
  wire tx;

  reg [8:0] currentData;
  reg [3:0] currentByte;

  SerialTX stx (clk, send, data, busy, tx);

  reg [baudGenWidth-1:0] lastBaudDivider = 0;

  // Test Baud Clock
  always @(posedge clk)
  begin
    if (lastBaudDivider == baudMax && stx.baudDivider != 0)
    begin
      $error("Expected baud divider to overflow on %d. baudDivider[%d] lastBaudDivider[%d]", baudMax, stx.baudDivider, lastBaudDivider);
    end

    if (stx.baudDivider == 0 && lastBaudDivider != baudMax)
    begin
      $error("Expected baud divider to overflow on %d. Got overflow at %d", baudMax, lastBaudDivider);
    end

    if (stx.baudDivider == baudMax && ~stx.baudClock)
    begin
      $error("Expected baud clock to tick when baudDivider overflows.");
    end

    lastBaudDivider <= stx.baudDivider;
  end

  // Test if Serial is outputing bytes
  initial begin
    $dumpfile("TX_tb.vcd");
    $dumpvars(0,SerialTXTest);
    for (currentData = 0; currentData < 256; currentData = currentData + 1)
    begin
      // $display("Testing byte %h", currentData);
      #period
      data = currentData;
      send = 1;
      #period
      send = 0;
      data = 8'hFF;
      #period

      // Test Start Bit
      repeat (2) @(posedge stx.baudClock);
      if (tx)
        $error("Expected start bit but got 1");

      // Test bits
      for (currentByte = 0; currentByte < 8; currentByte = currentByte + 1)
      begin
        repeat (1) @(posedge stx.baudClock);
        if (tx != currentData[currentByte])
        begin
          $error("Expected bit [%d] from byte to be %d but got %d.", currentByte, currentData[currentByte], tx);
        end
      end

      // Stop bit
      repeat (1) @(posedge stx.baudClock);
      if (~tx)
        $error("Expected stop bit but got 0");
      wait(~stx.busy);
    end
    $finish;
  end

endmodule