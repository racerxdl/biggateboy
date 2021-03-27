`timescale 1 ns/1 ns  // time-unit = 1 ns, precision = 10 ps

module ProgramCounterTest;

  localparam ms = 1e6;
  localparam us = 1e3;

  integer i, j;

  reg           clk = 0;
  reg           reset = 0;
  reg   [15:0]  dataIn;
  wire  [15:0]  dataOut;
  reg           writeEnable;     // 1 => WRITE, 0 => READ
  reg           countEnable;     // 1 => COUNT UP, 0 => STOPPED
  reg           writeAdd;        // 1 => Add to PC, 0 => Set to PC

  // Our device under test
  ProgramCounter dut(clk, reset, dataIn, dataOut, writeEnable, writeAdd, countEnable);

  initial begin
    $dumpfile("program_counter_tb.vcd");
    $dumpvars(0, ProgramCounterTest);
    // Set Reset conditions
    clk = 0;
    reset = 1;
    dataIn = 0;
    writeEnable = 0;
    countEnable = 0;
    writeAdd = 0;

    // Pulse Clock
    #10
    clk = 1;
    #10
    clk = 0;

    // Test reset
    if (dataOut != 0) $error("Expected dataOut to be %d but got %d.", 0, dataOut);
    if (dut.programCounter != 0) $error("Expected dut.programCounter to be %d but got %d.", 0, dut.programCounter);

    // Test Jump (Write-Set)
    dataIn = 16'hDEAD;
    writeEnable = 1;
    reset = 0;

    // Pulse Clock
    #10
    clk = 1;
    #10
    clk = 0;

    dataIn = 0;

    if (dataOut != 16'hDEAD) $error("Expected dataOut to be %d but got %d.", 16'hDEAD, dataOut);
    if (dut.programCounter != 16'hDEAD) $error("Expected dut.programCounter to be %d but got %d.", 16'hDEAD, dut.programCounter);

    // Test Jump (Write-Add)
    dut.programCounter = 16'hC;
    dataIn = 16'hFFFC; // -4
    writeEnable = 1;
    writeAdd = 1;
    reset = 0;

    // Pulse Clock
    #10
    clk = 1;
    #10
    clk = 0;

    dataIn = 0;

    if (dataOut != 16'h7) $error("Expected dataOut to be %d but got %d.", 16'h7, dataOut);
    if (dut.programCounter != 16'h7) $error("Expected dut.programCounter to be %d but got %d.", 16'h7, dut.programCounter);


    // Test Counter
    dataIn = 16'h0004;
    writeEnable = 1;
    writeAdd = 0;
    // Pulse Clock
    #10
    clk = 1;
    #10
    clk = 0;

    writeEnable = 0;
    countEnable = 1;

    for (i = 0; i < 16; i=i+1)
    begin
      if (dataOut != dataIn + i) $error("Expected dataOut to be %d but got %d.", dataIn + i, dataOut);
      // Pulse Clock
      #10
      clk = 1;
      #10
      clk = 0;
    end

    #100

    $finish;
  end
endmodule