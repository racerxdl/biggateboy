`timescale 1 ns/1 ns  // time-unit = 1 ns, precision = 10 ps

module CPUTest;

  localparam ms = 1e6;
  localparam us = 1e3;
  localparam memorySize = 65536;
  localparam timeoutClocks = 2000;

  localparam REGNUM_B = 4'h0;
  localparam REGNUM_C = 4'h1;
  localparam REGNUM_D = 4'h2;
  localparam REGNUM_E = 4'h3;
  localparam REGNUM_H = 4'h4;
  localparam REGNUM_L = 4'h5;
  localparam REGNUM_W = 4'h6;
  localparam REGNUM_Z = 4'h7;

  localparam FlagZeroBit      = 3; // Z
  localparam FlagSubBit       = 2; // N
  localparam FlagHalfCarryBit = 1; // H
  localparam FlagCarryBit     = 0; // C

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

    // ----------------------------//
    //          LOAD/STORE         //
    // ----------------------------//
    // $readmemh("testdata/test_load.mem", memory);

    // reset = 1;
    // #10
    // clk = 1;
    // #10
    // clk = 0;
    // reset = 0;

    // while (cpu.PC != 16'h14)
    // begin
    // #10
    // clk = 0;

    // #10
    // clk = 1;
    // end

    // // LD A, $10
    // // LD B, $11
    // // LD C, $12
    // // LD D, $13
    // // LD E, $14
    // // LD H, $15
    // // LD L, $16

    // if (cpu.RegA[7:0] != 8'h10) $error("Expected register A to be %02x got %02x", 8'h10, cpu.RegA[7:0]);
    // if (cpu.regBank.registers[REGNUM_B] != 8'h11) $error("Expected register B to be %02x got %02x", 8'h11, cpu.regBank.registers[REGNUM_B]);
    // if (cpu.regBank.registers[REGNUM_C] != 8'h12) $error("Expected register C to be %02x got %02x", 8'h12, cpu.regBank.registers[REGNUM_C]);
    // if (cpu.regBank.registers[REGNUM_D] != 8'h13) $error("Expected register D to be %02x got %02x", 8'h13, cpu.regBank.registers[REGNUM_D]);
    // if (cpu.regBank.registers[REGNUM_E] != 8'h14) $error("Expected register E to be %02x got %02x", 8'h14, cpu.regBank.registers[REGNUM_E]);
    // if (cpu.regBank.registers[REGNUM_H] != 8'h15) $error("Expected register H to be %02x got %02x", 8'h15, cpu.regBank.registers[REGNUM_H]);
    // if (cpu.regBank.registers[REGNUM_L] != 8'h16) $error("Expected register L to be %02x got %02x", 8'h16, cpu.regBank.registers[REGNUM_L]);

    // while (cpu.PC != 16'h28)
    // begin
    // #10
    // clk = 1;
    // #10
    // clk = 0;
    // end

    // // LD H, $FF
    // // LD L, $00
    // // LD [HL], 10
    // // NOP
    // // LD H, $FF
    // // LD L, $10
    // // LD A, $12
    // // LD [HL+], A
    // // LD [HL+], A
    // // LD [HL+], A
    // // LD [HL+], A
    // // LD [HL+], A

    // if (memory[16'hFF00] != 8'h10) $error("Expected memory %04x to be %02x got %02x", 16'hFF00, 8'h10, memory[16'hFF00]);

    // for (i = 0; i < 5; i++)
    // begin
    //   if (memory[16'hFF10 + i] != 8'h12) $error("Expected memory %04x to be %02x got %02x", 16'hFF10 + i, 8'h12, memory[16'hFF10 + i]);
    // end

    // while (cpu.PC != 16'h36)
    // begin
    // #10
    // clk = 1;
    // #10
    // clk = 0;
    // end

    // // LD A, $F0
    // // LD [HL-], A
    // // LD [HL-], A
    // // LD [HL-], A
    // // LD [HL-], A
    // // LD [HL-], A
    // // NOP
    // // NOP
    // // NOP
    // // NOP

    // for (i = 0; i < 5; i++)
    // begin
    //   if (memory[16'hFF10 + i] != 8'hF0) $error("Expected memory %04x to be %02x got %02x", 16'hFF10 + i, 8'hF0, memory[16'hFF10 + i]);
    // end


    // while (cpu.PC != 16'h44)
    // begin
    // #10
    // clk = 0;

    // #10
    // clk = 1;
    // end

    // // LD BC, $FF20
    // // LD DE, $FF21
    // // LD HL, $FF22
    // // LD SP, $FF23
    // // NOP

    // if (cpu.regBank.registers[REGNUM_B] != 8'hFF) $error("Expected register B to be %02x got %02x", 8'hFF, cpu.regBank.registers[REGNUM_B]);
    // if (cpu.regBank.registers[REGNUM_C] != 8'h20) $error("Expected register C to be %02x got %02x", 8'h20, cpu.regBank.registers[REGNUM_C]);
    // if (cpu.regBank.registers[REGNUM_D] != 8'hFF) $error("Expected register D to be %02x got %02x", 8'hFF, cpu.regBank.registers[REGNUM_D]);
    // if (cpu.regBank.registers[REGNUM_E] != 8'h21) $error("Expected register E to be %02x got %02x", 8'h21, cpu.regBank.registers[REGNUM_E]);
    // if (cpu.regBank.registers[REGNUM_H] != 8'hFF) $error("Expected register H to be %02x got %02x", 8'hFF, cpu.regBank.registers[REGNUM_H]);
    // if (cpu.regBank.registers[REGNUM_L] != 8'h22) $error("Expected register L to be %02x got %02x", 8'h22, cpu.regBank.registers[REGNUM_L]);
    // if (cpu.SP != 16'hFF23) $error("Expected register SP to be %04x got %04x", 16'hFF23, cpu.SP);

    // while (cpu.PC != 16'h50)
    // begin
    // #10
    // clk = 1;
    // #10
    // clk = 0;
    // end

    // // LD A, $F0
    // // LD [BC], A
    // // NOP
    // // LD A, $F1
    // // LD [DE], A
    // // NOP
    // // LD A, $F1
    // // LD [HL], A
    // // NOP

    // if (memory[16'hFF20] != 8'hF0) $error("Expected memory %04x to be %02x got %02x", 16'hFF20, 8'hF0, memory[16'hFF20]);
    // if (memory[16'hFF21] != 8'hF1) $error("Expected memory %04x to be %02x got %02x", 16'hFF21, 8'hF1, memory[16'hFF21]);
    // if (memory[16'hFF22] != 8'hF2) $error("Expected memory %04x to be %02x got %02x", 16'hFF22, 8'hF2, memory[16'hFF22]);

    // while (cpu.PC != 16'h54)
    // begin
    // #10
    // clk = 1;
    // #10
    // clk = 0;
    // end

    // // LD [$FF20], SP
    // // NOP
    // if (memory[16'hFF80] != 8'h23) $error("Expected memory %04x to be %02x got %02x", 16'hFF20, 8'h23, memory[16'hFF20]);
    // if (memory[16'hFF81] != 8'hFF) $error("Expected memory %04x to be %02x got %02x", 16'hFF21, 8'hFF, memory[16'hFF21]);

    // while (cpu.PC != 16'h5B)
    // begin
    // #10
    // clk = 1;
    // #10
    // clk = 0;
    // end

    // // LD A, [BC]
    // // LD B, A     ; Should be F0
    // // LD A, [DE]
    // // LD D, A     ; Should be F1
    // // LD A, [HL]
    // // LD H, A     ; Should be F2
    // // NOP

    // if (cpu.regBank.registers[REGNUM_B] != 8'hF0) $error("Expected register B to be %02x got %02x", 8'hF0, cpu.regBank.registers[REGNUM_B]);
    // if (cpu.regBank.registers[REGNUM_D] != 8'hF1) $error("Expected register D to be %02x got %02x", 8'hF1, cpu.regBank.registers[REGNUM_D]);
    // if (cpu.regBank.registers[REGNUM_H] != 8'hF2) $error("Expected register H to be %02x got %02x", 8'hF2, cpu.regBank.registers[REGNUM_H]);

    // while (cpu.PC != 16'h66)
    // begin
    // #10
    // clk = 1;
    // #10
    // clk = 0;
    // end

    // // LD A, $66
    // // LD [$FF00 + $60], A
    // // LD A, $80
    // // LD A, [$FF00 + $60]
    // // NOP

    // if (memory[16'hFF60] != 8'h66) $error("Expected memory %04x to be %02x got %02x", 16'hFF60, 8'h66, memory[16'hFF60]);
    // if (cpu.RegA[7:0] != 8'h66) $error("Expected register A to be %02x got %02x", 8'h66, cpu.RegA[7:0]);

    // while (cpu.PC != 16'h6C)
    // begin
    // #10
    // clk = 1;
    // #10
    // clk = 0;
    // end


    // // LD SP, $FF00
    // // LD HL, SP + $10
    // // NOP

    // if (cpu.regBank.registers[REGNUM_H] != 8'hFF) $error("Expected register H to be %02x got %02x", 8'hFF, cpu.regBank.registers[REGNUM_H]);
    // if (cpu.regBank.registers[REGNUM_L] != 8'h10) $error("Expected register L to be %02x got %02x", 8'h10, cpu.regBank.registers[REGNUM_L]);


    // while (cpu.PC != 16'h72)
    // begin
    // #10
    // clk = 1;
    // #10
    // clk = 0;
    // end

    // // LD SP, $FF0A
    // // LD HL, SP -5
    // // NOP

    // if (cpu.regBank.registers[REGNUM_H] != 8'hFF) $error("Expected register H to be %02x got %02x", 8'hFF, cpu.regBank.registers[REGNUM_H]);
    // if (cpu.regBank.registers[REGNUM_L] != 8'h05) $error("Expected register L to be %02x got %02x", 8'h05, cpu.regBank.registers[REGNUM_L]);

    // while (cpu.PC != 16'h7B)
    // begin
    // #10
    // clk = 1;
    // #10
    // clk = 0;
    // end

    // // LD C, $80
    // // LD A, $FC
    // // LD [$FF00 + C], A
    // // LD A, $00
    // // LD A, [$FF00 + C]
    // // NOP

    // if (memory[16'hFF80] != 8'hFC) $error("Expected memory %04x to be %02x got %02x", 16'hFF80, 8'hFC, memory[16'hFF80]);
    // if (cpu.RegA[7:0] != 8'hFC) $error("Expected register A to be %02x got %02x", 8'hFC, cpu.RegA[7:0]);

    // while (cpu.PC != 16'h86)
    // begin
    // #10
    // clk = 1;
    // #10
    // clk = 0;
    // end

    // // LD A, $88
    // // LD [$1000], A
    // // LD A, $FF
    // // LD A, [$1000]
    // // NOP

    // if (memory[16'h1000] != 8'h88) $error("Expected memory %04x to be %02x got %02x", 16'h1000, 8'h88, memory[16'h1000]);
    // if (cpu.RegA[7:0] != 8'h88) $error("Expected register A to be %02x got %02x", 8'h88, cpu.RegA[7:0]);

    // // ----------------------------//
    // //            INC/DEC          //
    // // ----------------------------//
    // for (i = 0; i < memorySize; i=i+1)
    // begin
    //   memory[i] = 32'b0;
    // end

    // $readmemh("testdata/test_incdec.mem", memory);

    // reset = 1;
    // #10
    // clk = 1;
    // #10
    // clk = 0;
    // reset = 0;

    // while (cpu.PC != 16'h18)
    // begin
    // #10
    // clk = 1;
    // #10
    // clk = 0;
    // end

    // // LD A, $10
    // // LD B, $11
    // // LD C, $12
    // // LD D, $13
    // // LD E, $14
    // // LD H, $15
    // // LD L, $16
    // // NOP
    // // INC A
    // // INC B
    // // INC C
    // // INC D
    // // INC E
    // // INC H
    // // INC L
    // // NOP

    // if (cpu.RegA[7:0] != 8'h11) $error("Expected register A to be %02x got %02x", 8'h11, cpu.RegA[7:0]);
    // if (cpu.regBank.registers[REGNUM_B] != 8'h12) $error("Expected register B to be %02x got %02x", 8'h12, cpu.regBank.registers[REGNUM_B]);
    // if (cpu.regBank.registers[REGNUM_C] != 8'h13) $error("Expected register C to be %02x got %02x", 8'h13, cpu.regBank.registers[REGNUM_C]);
    // if (cpu.regBank.registers[REGNUM_D] != 8'h14) $error("Expected register D to be %02x got %02x", 8'h14, cpu.regBank.registers[REGNUM_D]);
    // if (cpu.regBank.registers[REGNUM_E] != 8'h15) $error("Expected register E to be %02x got %02x", 8'h15, cpu.regBank.registers[REGNUM_E]);
    // if (cpu.regBank.registers[REGNUM_H] != 8'h16) $error("Expected register H to be %02x got %02x", 8'h16, cpu.regBank.registers[REGNUM_H]);
    // if (cpu.regBank.registers[REGNUM_L] != 8'h17) $error("Expected register L to be %02x got %02x", 8'h17, cpu.regBank.registers[REGNUM_L]);

    // while (cpu.PC != 16'h20)
    // begin
    // #10
    // clk = 1;
    // #10
    // clk = 0;
    // end

    // // DEC A
    // // DEC B
    // // DEC C
    // // DEC D
    // // DEC E
    // // DEC H
    // // DEC L
    // // NOP
    // if (cpu.RegA[7:0] != 8'h10) $error("Expected register A to be %02x got %02x", 8'h10, cpu.RegA[7:0]);
    // if (cpu.regBank.registers[REGNUM_B] != 8'h11) $error("Expected register B to be %02x got %02x", 8'h11, cpu.regBank.registers[REGNUM_B]);
    // if (cpu.regBank.registers[REGNUM_C] != 8'h12) $error("Expected register C to be %02x got %02x", 8'h12, cpu.regBank.registers[REGNUM_C]);
    // if (cpu.regBank.registers[REGNUM_D] != 8'h13) $error("Expected register D to be %02x got %02x", 8'h13, cpu.regBank.registers[REGNUM_D]);
    // if (cpu.regBank.registers[REGNUM_E] != 8'h14) $error("Expected register E to be %02x got %02x", 8'h14, cpu.regBank.registers[REGNUM_E]);
    // if (cpu.regBank.registers[REGNUM_H] != 8'h15) $error("Expected register H to be %02x got %02x", 8'h15, cpu.regBank.registers[REGNUM_H]);
    // if (cpu.regBank.registers[REGNUM_L] != 8'h16) $error("Expected register L to be %02x got %02x", 8'h16, cpu.regBank.registers[REGNUM_L]);

    // while (cpu.PC != 16'h31)
    // begin
    // #10
    // clk = 1;
    // #10
    // clk = 0;
    // end

    // if (cpu.regBank.registers[REGNUM_B] != 8'h0F) $error("Expected register B to be %02x got %02x", 8'h0F, cpu.regBank.registers[REGNUM_B]);
    // if (cpu.regBank.registers[REGNUM_C] != 8'hFF) $error("Expected register C to be %02x got %02x", 8'hFF, cpu.regBank.registers[REGNUM_C]);
    // if (cpu.regBank.registers[REGNUM_D] != 8'h1F) $error("Expected register D to be %02x got %02x", 8'h1F, cpu.regBank.registers[REGNUM_D]);
    // if (cpu.regBank.registers[REGNUM_E] != 8'hFF) $error("Expected register E to be %02x got %02x", 8'hFF, cpu.regBank.registers[REGNUM_E]);
    // if (cpu.regBank.registers[REGNUM_H] != 8'h2F) $error("Expected register H to be %02x got %02x", 8'h2F, cpu.regBank.registers[REGNUM_H]);
    // if (cpu.regBank.registers[REGNUM_L] != 8'hFF) $error("Expected register L to be %02x got %02x", 8'hFF, cpu.regBank.registers[REGNUM_L]);
    // if (cpu.SP != 16'h3FFF)$error("Expected register SP to be %04x got %04x", 16'h3FFF, cpu.SP);


    // ----------------------------//
    //              JMP            //
    // ----------------------------//
    for (i = 0; i < memorySize; i=i+1)
    begin
      memory[i] = 32'b0;
    end

    $readmemh("testdata/test_jmp.mem", memory);

    reset = 1;
    #10
    clk = 1;
    #10
    clk = 0;
    reset = 0;

    while (cpu.PC != 16'h0C)
    begin
    #10
    clk = 1;
    #10
    clk = 0;
    end

    if (cpu.RegA[7:0] != 8'h02) $error("Expected register A to be %02x got %02x", 8'h02, cpu.RegA[7:0]);

    while (cpu.PC != 16'h1F)
    begin
    #10
    clk = 1;
    #10
    clk = 0;
    end

    if (cpu.RegA[7:0] != 8'h02) $error("Expected register A to be %02x got %02x", 8'h02, cpu.RegA[7:0]);


    while (cpu.PC != 16'h27)
    begin
    #10
    clk = 1;
    #10
    clk = 0;
    end

    if (cpu.RegA[7:0] != 8'h03) $error("Expected register A to be %02x got %02x", 8'h03, cpu.RegA[7:0]);

    while (cpu.PC != 16'h34)
    begin
    #10
    clk = 1;
    #10
    clk = 0;
    end

    if (cpu.RegA[7:0] != 8'h01) $error("Expected register A to be %02x got %02x", 8'h01, cpu.RegA[7:0]);


    // Set Flag Zero
    cpu.alu.F[FlagZeroBit] = 1;

    while (cpu.PC != 16'h48)
    begin
    #10
    clk = 1;
    #10
    clk = 0;
    end
    if (cpu.RegA[7:0] != 8'h01) $error("Expected register A to be %02x got %02x", 8'h01, cpu.RegA[7:0]);
    cpu.alu.F[FlagZeroBit] = 0;

    cpu.alu.F[FlagCarryBit] = 1;
    while (cpu.PC != 16'h55)
    begin
    #10
    clk = 1;
    #10
    clk = 0;
    end
    if (cpu.RegA[7:0] != 8'h01) $error("Expected register A to be %02x got %02x", 8'h01, cpu.RegA[7:0]);
    cpu.alu.F[FlagCarryBit] = 0;

    cpu.alu.F[FlagZeroBit] = 1;
    while (cpu.PC != 16'h6D)
    begin
    #10
    clk = 1;
    #10
    clk = 0;
    end
    if (cpu.RegA[7:0] != 8'h01) $error("Expected register A to be %02x got %02x", 8'h01, cpu.RegA[7:0]);
    cpu.alu.F[FlagZeroBit] = 0;

    cpu.alu.F[FlagCarryBit] = 1;
    while (cpu.PC != 16'h7C)
    begin
    #10
    clk = 1;
    #10
    clk = 0;
    end
    if (cpu.RegA[7:0] != 8'h01) $error("Expected register A to be %02x got %02x", 8'h01, cpu.RegA[7:0]);




    // ----------------------------//
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

    repeat(1000)
    begin
    #10
    clk = 0;

    #10
    clk = 1;
    end
  end

endmodule