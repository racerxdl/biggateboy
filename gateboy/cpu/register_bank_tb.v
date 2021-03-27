`timescale 1 ns/1 ns  // time-unit = 1 ns, precision = 10 ps

module RegisterBankTest;

  localparam ms = 1e6;
  localparam us = 1e3;

  integer i, j;

  reg           clk = 0;
  reg           reset = 0;
  reg   [7:0]   dataIn;
  wire  [7:0]   dataOut;
  wire  [15:0]  dataOut16;
  reg   [2:0]   regNum;
  reg           writeEnable;     // 1 => WRITE, 0 => READ

  // Our device under test
  RegisterBank dut(clk, reset, dataIn, dataOut, dataOut16, regNum, writeEnable);

  initial begin
    $dumpfile("register_bank_tb.vcd");
    $dumpvars(0, RegisterBankTest);
    // Set Reset conditions
    clk = 0;
    reset = 1;
    dataIn = 0;
    regNum = 0;
    writeEnable = 0;

    for (i = 1; i < 8; i=i+1)
    begin
      dut.registers[i] = 0;
    end

    // Pulse Clock
    #10
    clk = 1;
    #10
    clk = 0;

    for (i = 0; i < 8; i=i+1)
    begin
      // Reset
      clk = 0;
      reset = 1;
      dataIn = 0;
      regNum = 0;
      writeEnable = 0;

      for (j = 0; j < 8; j=j+1)
      begin
        dut.registers[j] = 0;
      end

      // Pulse Clock
      #10
      clk = 1;
      #10
      clk = 0;

      // Set Register Value
      dataIn = 8'hFF;
      reset = 0;
      regNum = i;
      writeEnable = 1;

      // Pulse Clock
      #10
      clk = 1;
      #10
      clk = 0;

      // Verify Registers Internally
      for (j = 0; j < 8; j=j+1)
      begin
        if (j == i)
        begin
          if (dut.registers[j] != 8'hFF) $error("Expected registers[%d] to be %d but got %d.", j, 8'hFF, dut.registers[j]);
        end
        else
        begin
          if (dut.registers[j] != 0) $error("Expected registers[%d] to be %d but got %d.", j, 0, dut.registers[j]);
        end
      end

      // Test Read Only
      writeEnable = 0;
      dataIn = 32'hF0;

      // Pulse Clock
      #10
      clk = 1;
      #10
      clk = 0;

      if (dataOut != 32'hFF)
        $error("Expected dataOut to be %d but got %d.", 8'hFF, dataOut);
      if (dut.registers[i] != 8'hFF)
        $error("Expected registers[%d] to be %d but got %d.", 8'hFF, i, dut.registers[i]);
    end

    // Reset
    clk = 0;
    reset = 1;
    dataIn = 0;
    regNum = 0;
    writeEnable = 0;

    dut.registers[0] = 8'hDE;
    dut.registers[1] = 8'hAD;
    dut.registers[2] = 8'hBE;
    dut.registers[3] = 8'hEF;
    dut.registers[4] = 8'hBA;
    dut.registers[5] = 8'hBA;
    dut.registers[6] = 8'hBA;
    dut.registers[7] = 8'hBE;

    // ----------------- //

    regNum = 0;
    #10
    clk = 1;
    #10
    clk = 0;
    if (dataOut16 != 16'hDEAD) $error("Expected dataOut16[%d] to be %x but got %x.", i, 16'hDEAD, dataOut16);
    regNum = 1;
    #10
    clk = 1;
    #10
    clk = 0;
    if (dataOut16 != 16'hDEAD) $error("Expected dataOut16[%d] to be %x but got %x.", i, 16'hDEAD, dataOut16);

    // ----------------- //

    regNum = 2;
    #10
    clk = 1;
    #10
    clk = 0;
    if (dataOut16 != 16'hBEEF) $error("Expected dataOut16[%d] to be %x but got %x.", i, 16'hDEAD, dataOut16);
    regNum = 3;
    #10
    clk = 1;
    #10
    clk = 0;
    if (dataOut16 != 16'hBEEF) $error("Expected dataOut16[%d] to be %x but got %x.", i, 16'hDEAD, dataOut16);

    // ----------------- //

    regNum = 4;
    #10
    clk = 1;
    #10
    clk = 0;
    if (dataOut16 != 16'hBABA) $error("Expected dataOut16[%d] to be %x but got %x.", i, 16'hDEAD, dataOut16);
    regNum = 5;
    #10
    clk = 1;
    #10
    clk = 0;
    if (dataOut16 != 16'hBABA) $error("Expected dataOut16[%d] to be %x but got %x.", i, 16'hDEAD, dataOut16);

    // ----------------- //

    regNum = 6;
    #10
    clk = 1;
    #10
    clk = 0;
    if (dataOut16 != 16'hBABE) $error("Expected dataOut16[%d] to be %x but got %x.", i, 16'hDEAD, dataOut16);
    regNum = 7;
    #10
    clk = 1;
    #10
    clk = 0;
    if (dataOut16 != 16'hBABE) $error("Expected dataOut16[%d] to be %x but got %x.", i, 16'hDEAD, dataOut16);

    #100

    $finish;
  end
endmodule