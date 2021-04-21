`timescale 1 ns/1 ns  // time-unit = 1 ns, precision = 10 ps

module ALUTest;
  // Simulation helpers
  event terminateSimulation;
  reg [7:0] OpError     [128:0];
  reg [7:0] OpTotal     [128:0];
  integer seed = 0; // Random number seed
  integer i;

  `include "aluops.v"

  localparam numTests = 67; // Check testdata/gen_alu_tests.py

  // ALU Registers
  reg [7:0] op;
  reg [15:0] X;         // First Operand
  reg [15:0] Y;         // Second Operand
  reg [3:0]  F;         // Flag Register

  wire [3:0]  FResult;  // Result Flag
  wire [15:0] O;        // Operation Result

  // OP(8), X(16), Y(16), F(4), O(16), FResult(4) == Total(64)
  reg [63:0] testCases [0:numTests-1];

  // Test regs
  reg [7:0]   tOP;
  reg [15:0]  tX;
  reg [15:0]  tY;
  reg [3:0]   tF;

  reg [3:0]  tFResult;
  reg [15:0] tO;

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
    OpError[ALU_ADD]    = 0; OpTotal[ALU_ADD]    = 0;
    OpError[ALU_ADC]    = 0; OpTotal[ALU_ADC]    = 0;
    OpError[ALU_SUB]    = 0; OpTotal[ALU_SUB]    = 0;
    OpError[ALU_SBC]    = 0; OpTotal[ALU_SBC]    = 0;
    OpError[ALU_AND]    = 0; OpTotal[ALU_AND]    = 0;
    OpError[ALU_XOR]    = 0; OpTotal[ALU_XOR]    = 0;
    OpError[ALU_OR]     = 0; OpTotal[ALU_OR]     = 0;
    OpError[ALU_CP]     = 0; OpTotal[ALU_CP]     = 0;

    OpError[ALU_RLC]    = 0; OpTotal[ALU_RLC]    = 0;
    OpError[ALU_RRC]    = 0; OpTotal[ALU_RRC]    = 0;
    OpError[ALU_RL]     = 0; OpTotal[ALU_RL]     = 0;
    OpError[ALU_RR]     = 0; OpTotal[ALU_RR]     = 0;
    OpError[ALU_DAA]    = 0; OpTotal[ALU_DAA]    = 0;
    OpError[ALU_CPL]    = 0; OpTotal[ALU_CPL]    = 0;
    OpError[ALU_SCF]    = 0; OpTotal[ALU_SCF]    = 0;
    OpError[ALU_CCF]    = 0; OpTotal[ALU_CCF]    = 0;

    OpError[ALU_SLA]    = 0; OpTotal[ALU_SLA]    = 0;
    OpError[ALU_SRA]    = 0; OpTotal[ALU_SRA]    = 0;
    OpError[ALU_SRL]    = 0; OpTotal[ALU_SRL]    = 0;
    OpError[ALU_SWAP]   = 0; OpTotal[ALU_SWAP]   = 0;
    OpError[ALU_ADD16]  = 0; OpTotal[ALU_ADD16]  = 0;

    for (i = 0; i < 8; i++)
    begin
      OpError[ALU_BIT + i] = 0;
      OpTotal[ALU_BIT + i] = 0;
      OpError[ALU_RES + i] = 0;
      OpTotal[ALU_RES + i] = 0;
      OpError[ALU_SET + i] = 0;
      OpTotal[ALU_SET + i] = 0;
    end

    $display("\033[1;37m## Running tests\033[0m");
    for (i = 0; i < numTests; i++)
    begin
      {tOP, tX, tY, tF, tO, tFResult} = testCases[i];
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
    if (OpError[ALU_OR]    == 0) $display("| \033[1;32mALU  OR     ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_OR   ], OpTotal[ALU_OR   ]); else $display("| \033[1;31mALU  OR     ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_OR   ], OpTotal[ALU_OR   ]);
    if (OpError[ALU_AND]   == 0) $display("| \033[1;32mALU  AND    ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_AND  ], OpTotal[ALU_AND  ]); else $display("| \033[1;31mALU  AND    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_AND  ], OpTotal[ALU_AND  ]);
    if (OpError[ALU_XOR]   == 0) $display("| \033[1;32mALU  XOR    ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_XOR  ], OpTotal[ALU_XOR  ]); else $display("| \033[1;31mALU  XOR    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_XOR  ], OpTotal[ALU_XOR  ]);
    if (OpError[ALU_CPL]   == 0) $display("| \033[1;32mALU  CPL    ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_CPL  ], OpTotal[ALU_CPL  ]); else $display("| \033[1;31mALU  CPL    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_CPL  ], OpTotal[ALU_CPL  ]);
    if (OpError[ALU_ADD]   == 0) $display("| \033[1;32mALU  ADD    ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_ADD  ], OpTotal[ALU_ADD  ]); else $display("| \033[1;31mALU  ADD    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_ADD  ], OpTotal[ALU_ADD  ]);
    if (OpError[ALU_ADC]   == 0) $display("| \033[1;32mALU  ADC    ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_ADC  ], OpTotal[ALU_ADC  ]); else $display("| \033[1;31mALU  ADC    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_ADC  ], OpTotal[ALU_ADC  ]);
    if (OpError[ALU_SUB]   == 0) $display("| \033[1;32mALU  SUB    ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_SUB  ], OpTotal[ALU_SUB  ]); else $display("| \033[1;31mALU  SUB    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_SUB  ], OpTotal[ALU_SUB  ]);
    if (OpError[ALU_SBC]   == 0) $display("| \033[1;32mALU  SBC    ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_SBC  ], OpTotal[ALU_SBC  ]); else $display("| \033[1;31mALU  SBC    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_SBC  ], OpTotal[ALU_SBC  ]);
    if (OpError[ALU_RLC]   == 0) $display("| \033[1;32mALU  RLC    ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_RLC  ], OpTotal[ALU_RLC  ]); else $display("| \033[1;31mALU  RLC    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_RLC  ], OpTotal[ALU_RLC  ]);
    if (OpError[ALU_RL]    == 0) $display("| \033[1;32mALU  RL     ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_RL   ], OpTotal[ALU_RL   ]); else $display("| \033[1;31mALU  RL     ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_RL   ], OpTotal[ALU_RL   ]);
    if (OpError[ALU_RRC]   == 0) $display("| \033[1;32mALU  RRC    ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_RRC  ], OpTotal[ALU_RRC  ]); else $display("| \033[1;31mALU  RRC    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_RRC  ], OpTotal[ALU_RRC  ]);
    if (OpError[ALU_RR]    == 0) $display("| \033[1;32mALU  RR     ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_RR   ], OpTotal[ALU_RR   ]); else $display("| \033[1;31mALU  RR     ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_RR   ], OpTotal[ALU_RR   ]);
    if (OpError[ALU_SLA]   == 0) $display("| \033[1;32mALU  SLA    ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_SLA  ], OpTotal[ALU_SLA  ]); else $display("| \033[1;31mALU  SLA    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_SLA  ], OpTotal[ALU_SLA  ]);
    if (OpError[ALU_SRA]   == 0) $display("| \033[1;32mALU  SRA    ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_SRA  ], OpTotal[ALU_SRA  ]); else $display("| \033[1;31mALU  SRA    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_SRA  ], OpTotal[ALU_SRA  ]);
    if (OpError[ALU_SRL]   == 0) $display("| \033[1;32mALU  SRL    ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_SRL  ], OpTotal[ALU_SRL  ]); else $display("| \033[1;31mALU  SRL    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_SRL  ], OpTotal[ALU_SRL  ]);
    if (OpError[ALU_SWAP]  == 0) $display("| \033[1;32mALU  SWAP   ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_SWAP ], OpTotal[ALU_SWAP ]); else $display("| \033[1;31mALU  SWAP   ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_SWAP ], OpTotal[ALU_SWAP ]);
    if (OpError[ALU_DAA]   == 0) $display("| \033[1;32mALU  DAA    ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_DAA  ], OpTotal[ALU_DAA  ]); else $display("| \033[1;31mALU  DAA    ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_DAA  ], OpTotal[ALU_DAA  ]);
    if (OpError[ALU_ADD16] == 0) $display("| \033[1;32mALU  ADD16  ==   OK   [%d    /  %d  ]\033[0m |", OpError[ALU_ADD16], OpTotal[ALU_ADD16]); else $display("| \033[1;31mALU  ADD16  ==  NOK   [%d    /  %d  ]\033[0m |", OpError[ALU_ADD16], OpTotal[ALU_ADD16]);

    for (i = 0; i < 8; i++)
    begin
      if (OpError[ALU_BIT + i] == 0)
        $display("| \033[1;32mALU  BIT%01d   ==   OK   [%d    /  %d  ]\033[0m |", i, OpError[ALU_BIT + i], OpTotal[ALU_BIT + i]);
      else
        $display("| \033[1;31mALU  BIT%01d   ==  NOK   [%d    /  %d  ]\033[0m |", i, OpError[ALU_BIT + i], OpTotal[ALU_BIT + i]);
    end
    for (i = 0; i < 8; i++)
    begin
      if (OpError[ALU_RES + i] == 0)
        $display("| \033[1;32mALU  RES%01d   ==   OK   [%d    /  %d  ]\033[0m |", i, OpError[ALU_RES + i], OpTotal[ALU_RES + i]);
      else
        $display("| \033[1;31mALU  RES%01d   ==  NOK   [%d    /  %d  ]\033[0m |", i, OpError[ALU_RES + i], OpTotal[ALU_RES + i]);
    end
    for (i = 0; i < 8; i++)
    begin
      if (OpError[ALU_SET + i] == 0)
        $display("| \033[1;32mALU  SET%01d   ==   OK   [%d    /  %d  ]\033[0m |", i, OpError[ALU_SET + i], OpTotal[ALU_SET + i]);
      else
        $display("| \033[1;31mALU  SET%01d   ==  NOK   [%d    /  %d  ]\033[0m |", i, OpError[ALU_SET + i], OpTotal[ALU_SET + i]);
    end
    $display("  ----------------------------------------\n");
    $display("\033[1;37m###################################################\033[0m");
    $finish;
  end

endmodule
