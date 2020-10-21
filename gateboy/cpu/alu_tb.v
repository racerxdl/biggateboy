`timescale 1 ns/1 ns  // time-unit = 1 ns, precision = 10 ps

module ALUTest;
  // Simulation helpers
  event terminateSimulation;
  reg [7:0] OpError     [17:0];
  reg [7:0] OpTotal     [17:0];
  integer seed = 0; // Random number seed
  integer i;

  localparam numTests = 27; // Check testdata/gen_alu_tests.py

  // ALU Registers
  reg [4:0] op;
  reg [15:0] X;         // First Operand
  reg [15:0] Y;         // Second Operand
  reg [3:0]  F;         // Flag Register

  wire [3:0]  FResult;  // Result Flag
  wire [15:0] O;        // Operation Result

  // OP(5), X(16), Y(16), F(4), O(16), FResult(4), Padding(3) == Total(64)
  reg [63:0] testCases [0:numTests-1];

  // Test regs
  reg [4:0]   tOP;
  reg [15:0]  tX;
  reg [15:0]  tY;
  reg [3:0]   tF;

  reg [3:0]  tFResult;
  reg [15:0] tO;
  reg [2:0]  tPad;

  reg currentOpErr;

  // Our device under test
  ALU alu(op, X, Y, F, FResult, O);

  initial begin
    $display("\033[1;37m###################################################\033[0m");
    $display("\033[1;37mALU Testing\033[0m");
    $dumpfile("ALU_tb.vcd");
    $dumpvars;
    // Load tests
    $readmemb("testdata/alu_tests.mem", testCases);

    // Reset errors
    OpError[alu.OR]     = 0; OpTotal[alu.OR]     = 0;
    OpError[alu.AND]    = 0; OpTotal[alu.AND]    = 0;
    OpError[alu.XOR]    = 0; OpTotal[alu.XOR]    = 0;
    OpError[alu.CPL]    = 0; OpTotal[alu.CPL]    = 0;
    OpError[alu.ADD]    = 0; OpTotal[alu.ADD]    = 0;
    OpError[alu.ADC]    = 0; OpTotal[alu.ADC]    = 0;
    OpError[alu.SUB]    = 0; OpTotal[alu.SUB]    = 0;
    OpError[alu.SBC]    = 0; OpTotal[alu.SBC]    = 0;
    OpError[alu.RLC]    = 0; OpTotal[alu.RLC]    = 0;
    OpError[alu.RL]     = 0; OpTotal[alu.RL]     = 0;
    OpError[alu.RRC]    = 0; OpTotal[alu.RRC]    = 0;
    OpError[alu.RR]     = 0; OpTotal[alu.RR]     = 0;
    OpError[alu.SLA]    = 0; OpTotal[alu.SLA]    = 0;
    OpError[alu.SRA]    = 0; OpTotal[alu.SRA]    = 0;
    OpError[alu.SRL]    = 0; OpTotal[alu.SRL]    = 0;
    OpError[alu.SWAP]   = 0; OpTotal[alu.SWAP]   = 0;
    OpError[alu.DAA]    = 0; OpTotal[alu.DAA]    = 0;
    OpError[alu.ADD16]  = 0; OpTotal[alu.ADD16]  = 0;

    $display("\033[1;37m## Running tests\033[0m");
    for (i = 0; i < numTests; i++)
    begin
      {tOP, tX, tY, tF, tO, tFResult, tPad} = testCases[i];
      #1
      $display("\033[1;34m  -- Running test %d: %x\033[0m", i, testCases[i]);
      F  = tF;
      X  = tX;
      Y  = tY;
      op = tOP;
      #1
      currentOpErr = 0;
      #1
      if (O != tO) begin
        $display("\033[1;31m    -- Expected O(%d) = tO(%d)\033[0m", O, tO);
        currentOpErr = 1;
      end
      #1
      if (FResult != tFResult)
      begin
        $display("\033[1;31m    -- Expected FResult(%b) = tFResult(%b)\033[0m", FResult, tFResult);
        currentOpErr = 1;
      end
      #1
      if (currentOpErr) OpError[op] = OpError[op] + 1;
      OpTotal[op] = OpTotal[op] + 1;
    end
    -> terminateSimulation;
  end

  initial
  @ (terminateSimulation) begin
    $display("\033[1;37m## Results\033[0m\n");
    $display("\033[1;37m  ALU  OPER   == STATUS [ ERROR / TOTAL ]\033[0m");
    $display("  ----------------------------------------");
    if (OpError[alu.OR]    == 0) $display("| \033[1;32mALU  OR     ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.OR   ], OpTotal[alu.OR   ]); else $display("| \033[1;31mALU  OR     ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.OR   ], OpTotal[alu.OR   ]);
    if (OpError[alu.AND]   == 0) $display("| \033[1;32mALU  AND    ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.AND  ], OpTotal[alu.AND  ]); else $display("| \033[1;31mALU  AND    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.AND  ], OpTotal[alu.AND  ]);
    if (OpError[alu.XOR]   == 0) $display("| \033[1;32mALU  XOR    ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.XOR  ], OpTotal[alu.XOR  ]); else $display("| \033[1;31mALU  XOR    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.XOR  ], OpTotal[alu.XOR  ]);
    if (OpError[alu.CPL]   == 0) $display("| \033[1;32mALU  CPL    ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.CPL  ], OpTotal[alu.CPL  ]); else $display("| \033[1;31mALU  CPL    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.CPL  ], OpTotal[alu.CPL  ]);
    if (OpError[alu.ADD]   == 0) $display("| \033[1;32mALU  ADD    ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.ADD  ], OpTotal[alu.ADD  ]); else $display("| \033[1;31mALU  ADD    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.ADD  ], OpTotal[alu.ADD  ]);
    if (OpError[alu.ADC]   == 0) $display("| \033[1;32mALU  ADC    ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.ADC  ], OpTotal[alu.ADC  ]); else $display("| \033[1;31mALU  ADC    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.ADC  ], OpTotal[alu.ADC  ]);
    if (OpError[alu.SUB]   == 0) $display("| \033[1;32mALU  SUB    ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.SUB  ], OpTotal[alu.SUB  ]); else $display("| \033[1;31mALU  SUB    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.SUB  ], OpTotal[alu.SUB  ]);
    if (OpError[alu.SBC]   == 0) $display("| \033[1;32mALU  SBC    ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.SBC  ], OpTotal[alu.SBC  ]); else $display("| \033[1;31mALU  SBC    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.SBC  ], OpTotal[alu.SBC  ]);
    if (OpError[alu.RLC]   == 0) $display("| \033[1;32mALU  RLC    ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.RLC  ], OpTotal[alu.RLC  ]); else $display("| \033[1;31mALU  RLC    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.RLC  ], OpTotal[alu.RLC  ]);
    if (OpError[alu.RL]    == 0) $display("| \033[1;32mALU  RL     ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.RL   ], OpTotal[alu.RL   ]); else $display("| \033[1;31mALU  RL     ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.RL   ], OpTotal[alu.RL   ]);
    if (OpError[alu.RRC]   == 0) $display("| \033[1;32mALU  RRC    ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.RRC  ], OpTotal[alu.RRC  ]); else $display("| \033[1;31mALU  RRC    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.RRC  ], OpTotal[alu.RRC  ]);
    if (OpError[alu.RR]    == 0) $display("| \033[1;32mALU  RR     ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.RR   ], OpTotal[alu.RR   ]); else $display("| \033[1;31mALU  RR     ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.RR   ], OpTotal[alu.RR   ]);
    if (OpError[alu.SLA]   == 0) $display("| \033[1;32mALU  SLA    ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.SLA  ], OpTotal[alu.SLA  ]); else $display("| \033[1;31mALU  SLA    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.SLA  ], OpTotal[alu.SLA  ]);
    if (OpError[alu.SRA]   == 0) $display("| \033[1;32mALU  SRA    ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.SRA  ], OpTotal[alu.SRA  ]); else $display("| \033[1;31mALU  SRA    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.SRA  ], OpTotal[alu.SRA  ]);
    if (OpError[alu.SRL]   == 0) $display("| \033[1;32mALU  SRL    ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.SRL  ], OpTotal[alu.SRL  ]); else $display("| \033[1;31mALU  SRL    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.SRL  ], OpTotal[alu.SRL  ]);
    if (OpError[alu.SWAP]  == 0) $display("| \033[1;32mALU  SWAP   ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.SWAP ], OpTotal[alu.SWAP ]); else $display("| \033[1;31mALU  SWAP   ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.SWAP ], OpTotal[alu.SWAP ]);
    if (OpError[alu.DAA]   == 0) $display("| \033[1;32mALU  DAA    ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.DAA  ], OpTotal[alu.DAA  ]); else $display("| \033[1;31mALU  DAA    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.DAA  ], OpTotal[alu.DAA  ]);
    if (OpError[alu.ADD16] == 0) $display("| \033[1;32mALU  ADD16  ==   OK   [%d    /  %d  ]\033[0m |", OpError[alu.ADD16], OpTotal[alu.ADD16]); else $display("| \033[1;31mALU  ADD16  ==  NOK   [%d    /  %d  ]\033[0m |", OpError[alu.ADD16], OpTotal[alu.ADD16]);
    $display("  ----------------------------------------\n");
    $display("\033[1;37m###################################################\033[0m");
    $finish;
  end

endmodule
