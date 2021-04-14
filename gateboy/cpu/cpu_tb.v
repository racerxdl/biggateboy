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

    $readmemh("testdata/test_load.mem", memory);

    reset = 1;
    #10
    clk = 1;
    #10
    clk = 0;
    reset = 0;

    while (cpu.PC != 16'h14)
    begin
    #10
    clk = 0;

    #10
    clk = 1;
    end

    // LD A, $10
    // LD B, $11
    // LD C, $12
    // LD D, $13
    // LD E, $14
    // LD H, $15
    // LD L, $16

    if (cpu.RegA[7:0] != 8'h10) $error("Expected register A to be %02x got %02x", 8'h10, cpu.RegA[7:0]);
    if (cpu.regBank.registers[0] != 8'h11) $error("Expected register B to be %02x got %02x", 8'h10, cpu.regBank.registers[0]);
    if (cpu.regBank.registers[1] != 8'h12) $error("Expected register C to be %02x got %02x", 8'h10, cpu.regBank.registers[1]);
    if (cpu.regBank.registers[2] != 8'h13) $error("Expected register D to be %02x got %02x", 8'h10, cpu.regBank.registers[2]);
    if (cpu.regBank.registers[3] != 8'h14) $error("Expected register E to be %02x got %02x", 8'h10, cpu.regBank.registers[3]);
    if (cpu.regBank.registers[4] != 8'h15) $error("Expected register H to be %02x got %02x", 8'h10, cpu.regBank.registers[4]);
    if (cpu.regBank.registers[5] != 8'h16) $error("Expected register L to be %02x got %02x", 8'h10, cpu.regBank.registers[5]);

    while (cpu.PC != 16'h28)
    begin
    #10
    clk = 0;

    #10
    clk = 1;
    end

    // LD H, $FF
    // LD L, $00
    // LD [HL], 10
    // NOP
    // LD H, $FF
    // LD L, $10
    // LD A, $12
    // LD [HL+], A
    // LD [HL+], A
    // LD [HL+], A
    // LD [HL+], A
    // LD [HL+], A

    if (memory[16'hFF00] != 8'h10) $error("Expected memory %04x to be %02x got %02x", 16'hFF00, 8'h10, memory[16'hFF00]);

    for (i = 0; i < 5; i++)
    begin
      if (memory[16'hFF10 + i] != 8'h12) $error("Expected memory %04x to be %02x got %02x", 16'hFF10 + i, 8'h12, memory[16'hFF10 + i]);
    end

    while (cpu.PC != 16'h38)
    begin
    #10
    clk = 0;

    #10
    clk = 1;
    end

    // LD A, $F0
    // LD [HL-], A
    // LD [HL-], A
    // LD [HL-], A
    // LD [HL-], A
    // LD [HL-], A
    // NOP
    // NOP
    // NOP
    // NOP

    for (i = 0; i < 5; i++)
    begin
      if (memory[16'hFF10 + i] != 8'hF0) $error("Expected memory %04x to be %02x got %02x", 16'hFF10 + i, 8'hF0, memory[16'hFF10 + i]);
    end

    // // Run GB Bios
    // for (i = 0; i < memorySize; i=i+1)
    // begin
    //   memory[i] = 32'b0;
    // end
    // $readmemh("testdata/gbbios.smem", memory);

    // reset = 1;
    // #10
    // clk = 1;
    // #10
    // clk = 0;

    // reset = 0;

    // while (cpu.PC != 16'h4D)
    // begin
    // #10
    // clk = 0;

    // #10
    // clk = 1;
    // end

    // repeat(1000)
    // begin
    // #10
    // clk = 0;

    // #10
    // clk = 1;
    // end
  end

endmodule