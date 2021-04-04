`timescale 1 ns/1 ns  // time-unit = 1 ns, precision = 10 ps

module CPUTest;

  localparam ms = 1e6;
  localparam us = 1e3;
  localparam memorySize = 65536;
  localparam timeoutClocks = 2000;

  integer i, j;

  reg           clk = 0;
  reg           reset = 0;
  reg   [7:0]   dataIn;
  wire  [7:0]   dataOut;
  wire  [15:0]  address;
  wire          busWriteEnable;     // 1 => WRITE, 0 => READ

  reg   [7:0]  memory [0:memorySize-1];

  always @(posedge clk)
  begin
    if (reset)
      dataIn <= 0;
    else
    begin
      dataIn <= memory[address];
      if (busWriteEnable) memory[address] <= dataOut;
    end
  end


  // Our device under test
  CPU cpu(clk, reset, address, dataIn, dataOut, busWriteEnable);

  initial begin
    $dumpfile("cpu_test.vcd");
    $dumpvars(0, CPUTest);
    for (i = 0; i < memorySize; i=i+1)
    begin
      memory[i] = 32'b0;
    end

    $readmemh("testdata/gbbios.smem", memory);

    reset = 1;
    #10
    clk = 1;
    #10
    clk = 0;

    reset = 0;

    while (cpu.PC != 16'h0D)
    begin
    #10
    clk = 0;

    #10
    clk = 1;
    end

    repeat(1000)
    begin
    #10
    clk = 0;

    #10
    clk = 1;
    end
  end

endmodule