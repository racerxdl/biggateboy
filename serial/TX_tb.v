`timescale 1 ns/1 ns  // time-unit = 1 ns, precision = 10 ps

module SerialTXTest;
  /* Make a regular pulsing clock. */
  reg clk = 1;
  reg [7:0] data = 0;

  localparam period = 40; // 25Mhz clock
  localparam ms = 1e6;
  localparam us = 1e3;

  always #20 clk = !clk;

  wire signal;
  reg send = 0;
  wire busy;
  wire tx;


  SerialTX stx (clk, send, data, busy, tx);

  initial begin
     $dumpfile("TX_tb.vcd");
     $dumpvars(0,SerialTXTest);
     #period
     data = 8'hDE;
     send = 1;
     #period
     send = 0;
     data = 8'hFF;
     #108e3
     $finish;
  end

  // initial
  //    $monitor("At time %t, signal = %h (%0d)",
  //             $time, signal, signal);
endmodule // test