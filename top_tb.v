`timescale 1 ns/1 ns  // time-unit = 1 ns, precision = 10 ps

module GameboyTest;

  integer i;
  wire led;
  reg  rst;
  reg  clk;

  Gameboy gb(
    .clk(clk),
    .rst(rst),
    .led(led)
  );

  initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, GameboyTest);

    for (i = 0; i < 32678; i++)
    begin
      if (i < 16384) gb.vRam[i] = 0;
      if (i < 128) gb.hRam[i] = 0;
      if (i < 128) gb.IORegisters[i] = 0;

      gb.wRam[i] = 0;
    end

    rst = 1;
    clk = 0;
    repeat(16)
    begin
      #20
      clk = 1;
      #20
      clk = 0;
    end
    rst = 0;

    repeat(1024)
    begin
      #20
      clk = 1;
      #20
      clk = 0;
    end

    $finish;
  end

endmodule