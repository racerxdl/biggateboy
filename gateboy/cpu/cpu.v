module CPU (
  input  wire         clk,          // 4MHz clock
  input  wire         reset,
  output reg  [15:0]  memAddress,
  input  wire [7:0]   memDataR,
  output reg  [7:0]   memDataW,
  output reg          RW,            // R/W (0 == Read, 1 == Write)
  output reg          stopped,
  output reg          halted,
  input  wire [7:0]   interruptsEnabled, // Memory Mapped at 0xFFFF
  input  wire [7:0]   interruptsFired,
  output reg  [7:0]   resetInterrupt
);

// Synchronous ALU
reg   [15:0]    AluX            = 0;
reg   [15:0]    AluY            = 0;
reg   [7:0]     AluOp           = 0;
reg             AluEnable       = 0;
reg             AluWriteA       = 0;
reg             AluWriteF       = 0;

wire  [15:0]    RegA;
wire  [7:0]     RegF;
wire  [15:0]    AluO;

wire  [15:0]    MemAddressPlusOne   = memAddress + 1;
wire  [15:0]    MemAddressMinusOne  = memAddress - 1;

ALUSync alu(clk, reset, AluOp, AluX, AluY, AluEnable, AluWriteA, AluWriteF, RegA, AluO, RegF);

// Interrupts
localparam IntVblank  = 8'h01;
localparam IntLcdstat = 8'h02;
localparam IntTimer   = 8'h04;
localparam IntSerial  = 8'h08;
localparam IntJoypad  = 8'h10;
localparam AllInts    = IntVblank | IntLcdstat | IntTimer | IntTimer | IntSerial | IntJoypad;
reg HandleInterrupts = 0;
wire [7:0] interruptsToHandle = (interruptsEnabled & interruptsFired) & AllInts;


// Register Bank
reg   [2:0]     RegNum          = 0;

// 8 bit register bank
reg   [7:0]     RegBankIn       = 0;
wire  [7:0]     RegBankOut;
reg             RegWriteEnable8  = 0;

// 16 bit register bank
wire  [15:0]    RegBankOut16;
reg   [15:0]    RegBankIn16 = 0;
reg             RegWriteEnable16 = 0;

RegisterBank regBank(
  .clk(clk),
  .reset(reset),
  .regNum(RegNum),

  // 8 bit interface
  .dataIn(RegBankIn),
  .dataOut(RegBankOut),
  .writeEnable(RegWriteEnable8),

  // 16 bit interface
  .dataOut16(RegBankOut16),
  .dataIn16(RegBankIn16),
  .writeEnable16(RegWriteEnable16)
);

// Program Counter
reg   [15:0]      PC = 0;
reg   [15:0]      SP = 0;

wire  [15:0]    SPPlusOne   = SP + 1;
wire  [15:0]    SPMinusOne  = SP - 1;

localparam FETCH0     = 8'h00;
localparam FETCH1     = 8'h01;
localparam DECODE     = 8'h02;
localparam EXECUTE0   = 8'h03;
localparam EXECUTE1   = 8'h04;
localparam EXECUTE2   = 8'h05;
localparam EXECUTE3   = 8'h06;
localparam EXECUTE4   = 8'h07;
localparam EXECUTE5   = 8'h08;
localparam HALTED0    = 8'h09;
localparam HALTED1    = 8'h10;
localparam INTERRUPT0 = HALTED1 + 1;
localparam TRAP       = HALTED1 + 2;

localparam REGNUM_B = 4'h0;
localparam REGNUM_C = 4'h1;
localparam REGNUM_D = 4'h2;
localparam REGNUM_E = 4'h3;
localparam REGNUM_H = 4'h4;
localparam REGNUM_L = 4'h5;
localparam REGNUM_W = 4'h6;
localparam REGNUM_Z = 4'h7;


// ALU OPS
localparam ALU_ADD       = 8'h00;
localparam ALU_ADC       = 8'h01;
localparam ALU_SUB       = 8'h02;
localparam ALU_SBC       = 8'h03;
localparam ALU_AND       = 8'h04;
localparam ALU_XOR       = 8'h05;
localparam ALU_OR        = 8'h06;
localparam ALU_CP        = 8'h07;
//RLCA  RRCA  RLA RRA DAA CPL SCF CCF
localparam ALU_RLC       = 8'h10;
localparam ALU_RRC       = 8'h11;
localparam ALU_RL        = 8'h12;
localparam ALU_RR        = 8'h13;
localparam ALU_DAA       = 8'h14;
localparam ALU_CPL       = 8'h15;
localparam ALU_SCF       = 8'h16;
localparam ALU_CCF       = 8'h17;
// From Prefix CB
localparam ALU_CB_BASE   = 8'h20;
localparam ALU_SLA       = 8'h24;
localparam ALU_SRA       = 8'h25;
localparam ALU_SRL       = 8'h26;
localparam ALU_SWAP      = 8'h27;
localparam ALU_BIT       = 8'h30;
localparam ALU_RES       = 8'h40;
localparam ALU_SET       = 8'h50;

// 16 bit operations
localparam ALU_ADD16     = 8'h60;


localparam ALU_FLAG_ZERO      = 3; // Z
localparam ALU_FLAG_SUB       = 2; // N
localparam ALU_FLAG_HALFCARRY = 1; // H
localparam ALU_FLAG_CARRY     = 0; // C

reg [7:0] currentState          = FETCH0;
reg [7:0] currentInstruction    = 8'h00;
reg [7:0] currentCBInstruction  = 8'h00;

wire [1:0] InsX = currentInstruction[7:6];
wire [2:0] InsY = currentInstruction[5:3];
wire [2:0] InsZ = currentInstruction[2:0];

wire [1:0] CBInsX = currentCBInstruction[7:6];
wire [2:0] CBInsY = currentCBInstruction[5:3];
wire [2:0] CBInsZ = currentCBInstruction[2:0];

always @(posedge clk)
begin
  if (reset)
  begin
    // ALU Reset
    AluX                  <= 0;
    AluY                  <= 0;
    AluOp                 <= 0;
    AluEnable             <= 0;
    AluWriteA             <= 0;
    AluWriteF             <= 0;

    // Register Bank Reset
    RegBankIn             <= 0;
    RegBankIn16           <= 0;
    RegNum                <= 0;
    RegWriteEnable8       <= 0;
    RegWriteEnable16      <= 0;

    // Bus Reset
    memDataW              <= 0;
    RW                    <= 0;
    memAddress            <= 0;

    // Program Counter
    PC                    <= 0;
    SP                    <= 0;

    // State Machine
    currentState          <= FETCH0;
    currentInstruction    <= 0;
    currentCBInstruction  <= 0;

    // Interrupts
    HandleInterrupts      <= 0;
    stopped               <= 0;
    halted                <= 0;
  end
  else
  begin
    if (currentState == FETCH0)
    begin
      memAddress        <= PC;
      RW                <= 0;
      RegWriteEnable8   <= 0;
      RegWriteEnable16  <= 0;
      AluWriteA         <= 0;
      AluWriteF         <= 0;
      AluEnable         <= 0;
      if (HandleInterrupts && (interruptsToHandle > 0))
        currentState      <= INTERRUPT0;
      else
        currentState      <= FETCH1;
    end
    else if (currentState == INTERRUPT0)
    begin
      RegNum              <= REGNUM_Z;
      RegWriteEnable16    <= 1;
      HandleInterrupts    <= 0;
      currentState        <= EXECUTE3;    // CALL stage after loading a16, so we safely call that WZ address
      currentInstruction  <= 8'b11001101; // CALL a16

      // Priority handling
      if ((interruptsToHandle & IntVblank) > 0)
      begin
        resetInterrupt <= IntVblank;
        RegBankIn16    <= 16'h0040;
      end
      else if ((interruptsToHandle & IntLcdstat) > 0)
      begin
        resetInterrupt <= IntLcdstat;
        RegBankIn16    <= 16'h0048;
      end
      else if ((interruptsToHandle & IntTimer) > 0)
      begin
        resetInterrupt <= IntTimer;
        RegBankIn16    <= 16'h0050;
      end
      else if ((interruptsToHandle & IntSerial) > 0)
      begin
        resetInterrupt <= IntSerial;
        RegBankIn16    <= 16'h0058;
      end
      else if ((interruptsToHandle & IntJoypad) > 0)
      begin
        resetInterrupt <= IntJoypad;
        RegBankIn16    <= 16'h0060;
      end
    end
    else if (currentState == FETCH1)
    begin
      PC                  <= MemAddressPlusOne;
      memAddress          <= MemAddressPlusOne; // Pre-fetch
      currentState        <= DECODE;
    end
    else if(currentState == DECODE)
    begin
      currentInstruction  <= memDataR;
      currentState        <= EXECUTE0;
    end
    else
    begin
      case (InsX)
        2'b00: // Group 0
        begin
          case (InsZ)
            3'b000:
            begin
              casex (InsY)
                3'b000: // NOP
                  currentState <= FETCH0;
                3'b001: // LD [a16], SP   memory[a16] = SP
                begin
                  case (currentState)
                    EXECUTE0:
                    begin
                      RegNum          <= REGNUM_W;
                      RegWriteEnable8 <= 1;
                      RegBankIn       <= memDataR;
                      memAddress      <= MemAddressPlusOne;
                      PC              <= MemAddressPlusOne;
                      currentState    <= EXECUTE1;
                    end
                    EXECUTE1:
                    begin
                      RegWriteEnable8 <= 0;
                      currentState    <= EXECUTE2;
                      PC              <= MemAddressPlusOne;
                    end
                    EXECUTE2:
                    begin
                      RegWriteEnable8 <= 0;
                      memAddress      <= {memDataR, RegBankOut};
                      RW              <= 1;
                      memDataW        <= SP[7:0];
                      currentState    <= EXECUTE3;
                    end
                    EXECUTE3:
                    begin
                      memAddress      <= MemAddressPlusOne;
                      RW              <= 1;
                      memDataW        <= SP[15:8];
                      currentState    <= FETCH0;
                    end
                  endcase
                end
                3'b010: // STOP
                begin
                  stopped       <= 1;
                  currentState  <= HALTED0;
                end
                3'b011: // JR s8
                  case (currentState)
                    EXECUTE0:
                    begin
                      AluX          <= MemAddressPlusOne;
                      AluY          <= $signed(memDataR);
                      AluOp         <= ALU_ADD16;
                      currentState  <= EXECUTE1;
                    end
                    EXECUTE1:
                    begin
                      PC            <= AluO;
                      currentState  <= FETCH0;
                    end
                  endcase
                3'b1xx: // JR {NZ, Z, NC, C}, s8
                begin
                  case (currentState)
                  EXECUTE0:
                  begin
                    case (InsY[1:0])
                      2'b00:  // NZ
                      begin
                        currentState <= !(RegF[ALU_FLAG_ZERO]) ? EXECUTE1 : FETCH0;
                      end
                      2'b01: //  Z
                      begin
                        currentState <= (RegF[ALU_FLAG_ZERO]) ? EXECUTE1 : FETCH0;
                      end
                      2'b10: // NC
                      begin
                        currentState <= !(RegF[ALU_FLAG_CARRY]) ? EXECUTE1 : FETCH0;
                      end
                      2'b11: //  C
                      begin
                        currentState <= (RegF[ALU_FLAG_CARRY]) ? EXECUTE1 : FETCH0;
                      end
                    endcase
                    PC        <= MemAddressPlusOne;
                  end
                  EXECUTE1:
                  begin
                    PC           <= PC + $signed({{8{memDataR[7]}}, memDataR});
                    currentState <= FETCH0;
                  end
                  endcase
                end
              endcase
            end
            3'b001:
            begin
              if (InsY[0]) // ADD HL, {BC, DE, HL, SP}
              begin
                case (currentState)
                  EXECUTE0:
                  begin
                    if (InsY[2:1] != 2'b11) // Not SP
                      RegNum <= InsY[2:1] << 1;
                    currentState <= EXECUTE1;
                  end
                  EXECUTE1:
                  begin
                    AluX          <= (InsY[2:1] == 2'b11) ? SP : RegBankOut16;
                    AluOp         <= ALU_ADD16;
                    RegNum        <= REGNUM_L;
                    currentState  <= EXECUTE2;
                  end
                  EXECUTE2:
                  begin
                    AluY          <= RegBankOut16;
                    currentState  <= EXECUTE3;
                  end
                  EXECUTE3:
                  begin
                    RegBankIn16       <= AluO;
                    RegWriteEnable16  <= 1;
                    currentState      <= FETCH0;
                  end
                endcase
              end
              else          // LD {BC, DE, HL, SP}, d16
              begin
                case (currentState)
                  EXECUTE0:
                  begin
                    currentState    <= EXECUTE1;
                    memAddress      <= PC + 1;
                  end
                  EXECUTE1:
                  begin
                    if (InsY[2:1] == 2'b11)
                        SP[7:0] <= memDataR;
                    else
                    begin
                      RegNum          <= (InsY[2:1] << 1) + 1; // BC, DE, HL, SP
                      RegWriteEnable8 <= 1;
                      RegBankIn       <= memDataR;
                    end
                    memAddress      <= PC + 1;
                    PC              <= MemAddressPlusOne;
                    currentState    <= EXECUTE2;
                  end
                  EXECUTE2:
                  begin
                    if (InsY[2:1] == 2'b11)
                      SP[15:8] <= memDataR;
                    else
                    begin
                      RegNum          <= RegNum - 1; // BC, DE, HL, SP
                      RegBankIn       <= memDataR;
                    end
                    PC              <= MemAddressPlusOne;
                    currentState    <= FETCH0;
                  end
                endcase
              end
            end
            3'b010: // LD [YY], A or LD A, [YY]
            begin
              case (currentState)
                EXECUTE0:
                begin
                  casex (InsY[2:1])
                    2'b00: RegNum <= REGNUM_B; // BC
                    2'b01: RegNum <= REGNUM_D; // DE
                    2'b1x: RegNum <= REGNUM_H; // HL
                  endcase
                  currentState <= EXECUTE1;
                end
                EXECUTE1:
                begin
                  memAddress    <= RegBankOut16;
                  currentState  <= EXECUTE2;
                end
                EXECUTE2:
                begin
                  currentState  <= EXECUTE3; // Idle cycle
                end
                EXECUTE3:
                begin
                  if (InsY[0]) // From BUS
                  begin
                    AluEnable <= 0;
                    AluWriteA <= 1;
                    AluX      <= {8'h00, memDataR};
                  end
                  else
                  begin        // To BUS
                    memDataW   <= RegA[7:0];
                    RW         <= 1;
                  end
                  if (InsY[2]) // HL+ or HL-
                  begin
                    RegBankIn16       <= InsY[1] ? MemAddressMinusOne : MemAddressPlusOne;
                    RegWriteEnable16  <= 1;
                  end
                  currentState <= FETCH0;
                end
              endcase
            end
            3'b011: // INC/DEC {BC, DE, HL, SP}
            begin
              if (InsY[2:1] == 2'b11) // SP
              begin
                SP            <= InsY[0] ? SPMinusOne : SPPlusOne;
                currentState  <= FETCH0;
              end
              else
              begin
                case (currentState)
                  EXECUTE0:
                  begin
                    RegNum        <= InsY[2:1] << 1;
                    AluY          <= InsY[0] ? $signed(-1) : 1;
                    AluOp         <= ALU_ADD16;
                    currentState  <= EXECUTE1;
                  end
                  EXECUTE1:
                  begin
                    AluX          <= RegBankOut16;
                    currentState  <= EXECUTE2;
                  end
                  EXECUTE2:
                  begin
                    RegBankIn16       <= AluO;
                    RegWriteEnable16  <= 1;
                    currentState      <= FETCH0;
                  end
                endcase
              end
            end
            3'b100: // INC REG
            begin
              if (InsY == 3'b110) // [HL]
              begin
                case (currentState)
                  EXECUTE0:
                  begin
                    RegNum       <= REGNUM_H;
                    currentState <= EXECUTE1;
                  end
                  EXECUTE1:
                  begin
                    memAddress   <= RegBankOut16;
                    currentState <= EXECUTE2;
                  end
                  EXECUTE2:
                  begin
                    AluY          <= 1;
                    AluOp         <= ALU_ADD;
                    currentState  <= EXECUTE3; // Wait Read
                  end
                  EXECUTE3:
                  begin
                    AluX          <= memDataR;
                    currentState  <= EXECUTE4; // Wait Read
                  end
                  EXECUTE4:
                  begin
                    memDataW      <= AluO[7:0]; // Writeback
                    RW            <= 1;
                    currentState  <= FETCH0;
                  end
                endcase
              end
              else
              begin
                case (currentState)
                  EXECUTE0:
                  begin
                    RegNum        <= InsY;
                    AluY          <= 1;
                    AluOp         <= ALU_ADD;
                    currentState  <= EXECUTE1;
                  end
                  EXECUTE1:
                  begin
                    AluX          <= (InsY == 3'b111) ? RegA : RegBankOut;
                    AluEnable     <= 1;
                    AluWriteA     <= (InsY == 3'b111);
                    currentState  <= (InsY == 3'b111) ? FETCH0 : EXECUTE2;
                  end
                  EXECUTE2:
                  begin
                    RegBankIn       <= AluO;
                    RegWriteEnable8 <= 1;
                    AluEnable       <= 0;
                    currentState    <= FETCH0;
                  end
                endcase
              end
            end
            3'b101:
            begin
              if (InsY == 3'b110) // [HL]
              begin
                case (currentState)
                  EXECUTE0:
                  begin
                    RegNum       <= REGNUM_H;
                    currentState <= EXECUTE1;
                  end
                  EXECUTE1:
                  begin
                    memAddress   <= RegBankOut16;
                    currentState <= EXECUTE2;
                  end
                  EXECUTE2:
                  begin
                    AluY          <= $signed(-1);
                    AluOp         <= ALU_ADD;
                    currentState  <= EXECUTE3; // Wait Read
                  end
                  EXECUTE3:
                  begin
                    AluX          <= memDataR;
                    currentState  <= EXECUTE4; // Wait Read
                  end
                  EXECUTE4:
                  begin
                    memDataW      <= AluO[7:0]; // Writeback
                    RW            <= 1;
                    currentState  <= FETCH0;
                  end
                endcase
              end
              else
              begin
                case (currentState)
                  EXECUTE0:
                  begin
                    RegNum        <= InsY;
                    AluY          <= $signed(-1);
                    AluOp         <= ALU_ADD;
                    currentState  <= EXECUTE1;
                  end
                  EXECUTE1:
                  begin
                    AluX          <= (InsY == 3'b111) ? RegA : RegBankOut;
                    AluEnable     <= 1;
                    AluWriteA     <= (InsY == 3'b111);
                    currentState  <= (InsY == 3'b111) ? FETCH0 : EXECUTE2;
                  end
                  EXECUTE2:
                  begin
                    RegBankIn       <= AluO;
                    RegWriteEnable8 <= 1;
                    AluEnable       <= 0;
                    currentState    <= FETCH0;
                  end
                endcase
              end
            end
            3'b110:
            begin
              case (currentState)
                EXECUTE0:
                begin
                  currentState    <= EXECUTE1;
                  PC              <= MemAddressPlusOne;
                  if (InsY == 3'b111) // A
                  begin // REG_A
                    AluX            <= memDataR;
                    AluWriteA       <= 1;
                    AluEnable       <= 0;
                    currentState    <= FETCH0;
                  end
                  else if (InsY == 3'b110) // [HL]
                  begin
                    RegNum          <= REGNUM_H;
                    currentState    <= EXECUTE1;
                    memDataW        <= memDataR;
                  end
                  else
                  begin // B, C, D, E, H, L
                    RegNum          <= InsY;
                    RegWriteEnable8 <= 1;
                    RegBankIn       <= memDataR;
                    currentState    <= FETCH0;
                  end
                end
                EXECUTE1:
                begin
                  memAddress    <= RegBankOut16;
                  RW            <= 1;
                  currentState  <= FETCH0;
                end
              endcase
            end
            3'b111: // ALU Op
            begin
              case (currentState)
              EXECUTE0:
              begin
                AluOp         <= {ALU_RLC[7:3], InsY};
                AluX          <= RegA;
                AluWriteA     <= 1;
                AluEnable     <= 1;
                currentState  <= FETCH0;
              end
              endcase
            end
          endcase
        end
        2'b01: // Group 1
        begin
          if (InsY == 3'b110 && InsZ == 3'b110) // HALT
          begin
            if (HandleInterrupts)
            begin
              halted        <= 1;
              currentState  <= HALTED0;
            end
            else
            begin
              PC            <= PC + 1;   // HALT Bug
              currentState  <= FETCH0;
            end
          end
          else if (InsY == InsZ) // LD X, X
          begin
            currentState  <= FETCH0;
          end
          else if (InsY == 3'b110 || InsZ == 3'b110) // From / To memory
          begin
            case (currentState)
            EXECUTE0:
            begin
              // Get memory address to be used
              RegNum       <= REGNUM_H;
              currentState <= EXECUTE1;
            end
            EXECUTE1:
            begin
              memAddress    <= RegBankOut16;
              RegNum        <= InsY == 3'b110 ? InsZ : InsY;
              currentState  <= EXECUTE2;
            end
            EXECUTE2:
            begin
              if (InsY == 3'b110) // Writing TO memory
              begin
                memDataW  <= InsZ == 3'b111 ? RegA[7:0] : RegBankOut;
                RW        <= 1;
                currentState  <= FETCH0;
              end
              else
              begin
                currentState <= EXECUTE3; // Wait read
              end
            end
            EXECUTE3:
            begin
              if (InsY == 3'b111) // A
              begin
                AluX      <= memDataR;
                AluWriteA <= 1;
              end
              else
              begin
                RegBankIn       <= memDataR;
                RegWriteEnable8 <= 1;
              end
              currentState <= FETCH0; // Wait read
            end
            endcase
          end
          else if (InsY == 3'b111 || InsZ == 3'b111)
          begin
            if (InsZ == 3'b111)
            begin
              RegNum          <= InsY;
              RegWriteEnable8 <= 1;
              RegBankIn       <= RegA[7:0];
              currentState    <= FETCH0;
            end
            else
            begin
              case(currentState)
                EXECUTE0:
                begin
                  RegNum          <= InsZ;
                  currentState    <= EXECUTE1;
                end
                EXECUTE1:
                begin
                  AluX          <= {8'b0, RegBankOut};
                  AluWriteA     <= 1;
                  currentState  <= FETCH0;
                end
              endcase
            end
          end
          else
          begin
            case (currentState)
            EXECUTE0:
            begin
              RegNum            <= InsY;
              currentState      <= EXECUTE1;
            end
            EXECUTE1:
            begin
              RegNum            <= InsZ;
              RegBankIn         <= RegBankOut;
              RegWriteEnable8   <= 1;
              currentState      <= FETCH0;
            end
            endcase
          end
        end
        2'b10: // Group 2
        begin
          // ALU OP
          if (InsZ == 3'b111) // A
          begin
            case (currentState)
              EXECUTE0:
              begin
                AluOp         <= InsY;
                AluX          <= RegA;
                AluY          <= RegA;
                AluEnable     <= 1;
                AluWriteA     <= 1;
                currentState  <= EXECUTE1;
              end
              EXECUTE1:
              begin
                AluEnable     <= 0;
                AluWriteA     <= 0;
                currentState  <= FETCH0;
              end
            endcase
          end
          else if (InsZ == 3'b110) // [HL]
          begin
            case (currentState)
              EXECUTE0:
              begin
                RegNum        <= REGNUM_L;
                currentState  <= EXECUTE1;
              end
              EXECUTE1:
              begin
                memAddress    <= RegBankOut16;
                currentState  <= EXECUTE2;
              end
              EXECUTE2:
              begin
                AluOp         <= InsY;
                AluX          <= RegA;
                currentState  <= EXECUTE3;
              end
              EXECUTE3:
              begin
                AluY          <= memDataR;
                AluEnable     <= 1;
                AluWriteA     <= 1;
                currentState  <= FETCH0;
              end
            endcase
          end
          else
          begin
            case (currentState)
              EXECUTE0:
              begin
                AluOp         <= InsY;
                AluX          <= RegA;
                RegNum        <= InsZ;
                currentState  <= EXECUTE1;
              end
              EXECUTE1:
              begin
                AluEnable     <= 1;
                AluWriteA     <= 1;
                AluY          <= RegBankOut;
                currentState  <= EXECUTE2;
              end
              EXECUTE2:
              begin
                AluEnable     <= 0;
                AluWriteA     <= 0;
                currentState  <= FETCH0;
              end
            endcase
          end
        end
        2'b11: // Group 3
        begin
          case (InsZ)
            3'b000:
            begin
              if (InsY[2] == 0) // RET {NZ, Z, NC, C}
              begin
                  case (currentState)
                  EXECUTE0:
                  begin
                    case (InsY[1:0])
                      2'b00:  // NZ
                      begin
                        currentState <= !(RegF[ALU_FLAG_ZERO]) ? EXECUTE1 : FETCH0;
                      end
                      2'b01: //  Z
                      begin
                        currentState <= (RegF[ALU_FLAG_ZERO]) ? EXECUTE1 : FETCH0;
                      end
                      2'b10: // NC
                      begin
                        currentState <= !(RegF[ALU_FLAG_CARRY]) ? EXECUTE1 : FETCH0;
                      end
                      2'b11: //  C
                      begin
                        currentState <= (RegF[ALU_FLAG_CARRY]) ? EXECUTE1 : FETCH0;
                      end
                    endcase
                  end
                  EXECUTE1:
                  begin
                    currentInstruction  <= 8'b11001001;// Set to normal RET
                    currentState        <= EXECUTE0;
                  end
                  endcase
              end
              else if(InsY[0] == 0) // LD [0xFF00 + a8], A or LD A, [0xFF00 + a8]
              begin
                case (currentState)
                  EXECUTE0:
                  begin
                    PC         <= MemAddressPlusOne;
                    memAddress <= 16'hFF00 + memDataR;
                    if (InsY[1] == 0) // Writing to memory
                    begin
                      memDataW      <= RegA;
                      RW            <= 1;
                      currentState  <= FETCH0;
                    end
                    else
                      currentState  <= EXECUTE1; // Reading from memory
                  end
                  EXECUTE1:
                  begin
                    currentState  <= EXECUTE2; // Idle cycle
                  end
                  EXECUTE2:
                  begin
                    AluX          <= memDataR;
                    AluWriteA     <= 1;
                    AluEnable     <= 0;
                    currentState  <= FETCH0;
                  end
                endcase
              end
              else if (InsY == 3'b101) // ADD SP, s8
              begin
                currentState <= TRAP; // TODO
              end
              else // LD HL, SP + r8
              begin
                case (currentState)
                EXECUTE0:
                begin
                  RegNum        <= REGNUM_H;
                  AluX          <= SP;
                  AluY          <= $signed(memDataR);
                  AluOp         <= ALU_ADD16;
                  PC            <= MemAddressPlusOne;
                  currentState  <= EXECUTE1;
                end
                EXECUTE1:
                begin
                  RegBankIn16       <= AluO;
                  RegWriteEnable16  <= 1;
                  currentState      <= FETCH0;
                end
                endcase
              end
            end
            3'b001:
            begin
              if (InsY[0] == 0) // POP {BC, DE, HL, AF}
              begin
                case (currentState)
                  EXECUTE0:
                  begin
                    memAddress    <= SP;
                    SP            <= SPPlusOne;
                    currentState  <= EXECUTE1;
                  end
                  EXECUTE1:
                  begin
                    currentState  <= EXECUTE2;
                  end
                  EXECUTE2:
                  begin
                    if (InsY[2:1] != 2'b11) // If not AF
                    begin
                      RegWriteEnable8 <= 1;
                      RegBankIn       <= memDataR;
                      RegNum          <= (InsY[2:1] << 1);
                    end
                    else
                    begin
                      AluX[15:8] <= memDataR;
                      AluWriteF  <= 1;
                    end
                    memAddress      <= SP;
                    SP              <= SPPlusOne;
                    currentState    <= EXECUTE3;
                  end
                  EXECUTE3:
                  begin
                    currentState  <= EXECUTE4;
                    RegNum        <= RegNum + 1;
                  end
                  EXECUTE4:
                  begin
                    if (InsY[2:1] != 2'b11) // If not AF
                    begin
                      RegBankIn       <= memDataR;
                    end
                    else
                    begin
                      AluX[7:0]  <= memDataR;
                      AluWriteA  <= 1;
                    end
                    currentState    <= FETCH0;
                  end
                endcase
              end
              else if (InsY == 3'b001) // RET
              begin
                case (currentState)
                EXECUTE0:
                begin
                  RegNum        <= REGNUM_W;
                  memAddress    <= SP;
                  SP            <= SPPlusOne;
                  currentState  <= EXECUTE1;
                end
                EXECUTE1:
                begin
                  memAddress    <= SP;
                  SP            <= SPPlusOne;
                  currentState  <= EXECUTE2;
                end
                EXECUTE2:
                begin
                  RegWriteEnable8 <= 1;
                  RegBankIn       <= memDataR;
                  currentState    <= EXECUTE3;
                end
                EXECUTE3:
                begin
                  RegNum          <= REGNUM_Z;
                  RegBankIn       <= memDataR;
                  currentState    <= EXECUTE4;
                end
                EXECUTE4:
                begin
                  currentState    <= EXECUTE5;
                end
                EXECUTE5:
                begin
                  PC              <= RegBankOut16;
                  currentState    <= FETCH0;
                end
                endcase
              end
              else if (InsY == 3'b011) // RETI
              begin
                  case (currentState)
                  EXECUTE0:
                  begin
                    HandleInterrupts    <= 1;
                    currentInstruction  <= 8'b11001001;// Set to normal RET
                    currentState        <= EXECUTE0;
                  end
                  endcase
              end
              else if (InsY == 3'b101) // JP HL
              begin
                case (currentState)
                  EXECUTE0:
                  begin
                    RegNum        <= REGNUM_L;
                    currentState  <= EXECUTE1;
                  end
                  EXECUTE1:
                  begin
                    PC            <= RegBankOut16;
                    currentState  <= FETCH0;
                  end
                endcase
              end
              else                     // LD HL, SP
              begin
                case (currentState)
                  EXECUTE0:
                  begin
                    RegNum        <= REGNUM_L;
                    currentState  <= EXECUTE1;
                  end
                  EXECUTE1:
                  begin
                    SP            <= RegBankOut16;
                    currentState  <= FETCH0;
                  end
                endcase
              end
            end
            3'b010:
            begin
              if (InsY[2] == 0) // JP {NZ, Z, NC, C}, a16
              begin
                case (currentState)
                EXECUTE0:
                begin
                  case (InsY[1:0])
                    2'b00:  // NZ
                    begin
                      currentState  <= !(RegF[ALU_FLAG_ZERO]) ? EXECUTE1   : FETCH0;
                      PC            <= !(RegF[ALU_FLAG_ZERO]) ? PC         : PC + 2;
                    end
                    2'b01: //  Z
                    begin
                      currentState  <= (RegF[ALU_FLAG_ZERO])  ? EXECUTE1   : FETCH0;
                      PC            <= (RegF[ALU_FLAG_ZERO])  ? PC         : PC + 2;
                    end
                    2'b10: // NC
                    begin
                      currentState  <= !(RegF[ALU_FLAG_CARRY]) ? EXECUTE1  : FETCH0;
                      PC            <= !(RegF[ALU_FLAG_CARRY]) ? PC        : PC + 2;
                    end
                    2'b11: //  C
                    begin
                      currentState  <= (RegF[ALU_FLAG_CARRY]) ? EXECUTE1   : FETCH0;
                      PC            <= (RegF[ALU_FLAG_CARRY]) ? PC         : PC + 2;
                    end
                  endcase
                end
                EXECUTE1:
                begin
                  currentInstruction  <= 8'b11000011;// Set to normal JP a16
                  currentState        <= EXECUTE0;
                end
                endcase
              end
              else if (InsY[0] == 0) // LD [0xFF00 + C], A or LD A, [0xFF00 + C]
              begin
                case (currentState)
                  EXECUTE0:
                  begin
                    RegNum        <= REGNUM_C;
                    currentState  <= EXECUTE1;
                  end
                  EXECUTE1:
                  begin
                    memAddress <= 16'hFF00 + RegBankOut;
                    if (InsY[1] == 0) // Write to mem
                    begin
                      memDataW      <= RegA;
                      RW            <= 1;
                      currentState  <= FETCH0;
                    end
                    else
                    begin // Reading from memory
                      currentState  <= EXECUTE2;
                    end
                  end
                  EXECUTE2:
                  begin
                    currentState <= EXECUTE3;
                  end
                  EXECUTE3:
                  begin
                    AluX          <= memDataR;
                    AluWriteA     <= 1;
                    AluEnable     <= 0;
                    currentState  <= FETCH0;
                  end
                endcase
              end
              else  // LD [a16], A or LD [a16], A
              begin
                case (currentState)
                  EXECUTE0:
                  begin
                    RegNum          <= REGNUM_W;
                    RegWriteEnable8 <= 1;
                    RegBankIn       <= memDataR;
                    PC              <= MemAddressPlusOne;
                    memAddress      <= MemAddressPlusOne;
                    currentState    <= EXECUTE1;
                  end
                  EXECUTE1:
                  begin
                    currentState    <= EXECUTE2;
                    RegWriteEnable8 <= 0;
                    PC              <= MemAddressPlusOne;
                  end
                  EXECUTE2:
                  begin
                    memAddress      <= {memDataR, RegBankOut};
                    if (InsY[1] == 0) // TO memory
                    begin
                      RW            <= 1;
                      memDataW      <= RegA[7:0];
                      currentState  <= FETCH0;
                    end
                    else              // FROM memory
                      currentState <= EXECUTE3;
                  end
                  EXECUTE3:
                  begin
                    currentState <= EXECUTE4;
                  end
                  EXECUTE4:
                  begin
                    AluX          <= memDataR;
                    AluWriteA     <= 1;
                    currentState  <= FETCH0;
                  end
                endcase
              end
            end
            3'b011:
            begin
              case (InsY)
                3'b000: // JP a16
                begin
                  case (currentState)
                    EXECUTE0:
                    begin
                      RegNum          <= REGNUM_W;
                      RegWriteEnable8 <= 1;
                      RegBankIn       <= memDataR;
                      memAddress      <= MemAddressPlusOne;
                      currentState    <= EXECUTE1;
                    end
                    EXECUTE1:
                    begin
                      currentState  <= EXECUTE2;
                    end
                    EXECUTE2:
                    begin
                      PC            <= {memDataR, RegBankOut};
                      currentState  <= FETCH0;
                    end
                  endcase
                end
                3'b001: // CB d8
                  if (currentState == EXECUTE0) // Common State
                  begin
                    PC                    <= MemAddressPlusOne;
                    currentCBInstruction  <= memDataR;
                    // Pre-select bank
                    if (memDataR[2:0] == 3'b110) // [HL]
                      RegNum <= REGNUM_H;
                    else if (memDataR[2:0] != 3'b111) // not A
                      RegNum <= memDataR[2:0];
                    currentState          <= EXECUTE1;
                  end
                  else if (CBInsZ == 3'b110) // Memory Operation
                  begin
                    case (currentState)
                    EXECUTE1:
                    begin
                      // Set memory address
                      memAddress    <= RegBankOut16;
                      currentState  <= EXECUTE2;
                    end
                    EXECUTE2:
                    begin
                      case (CBInsX)
                        2'b00: // ALUOP2[y] RG0[z]
                          AluOp <= CBInsY > 3 ? ALU_CB_BASE + CBInsY : ALU_RLC + CBInsY;
                        2'b01: // BIT Y, RG0[z]
                          AluOp <= {ALU_BIT[7:3], CBInsY};
                        2'b10: // RES Y, RG0[z]
                          AluOp <= {ALU_RES[7:3], CBInsY};
                        2'b11: // SET Y, RG0[z]
                          AluOp <= {ALU_SET[7:3], CBInsY};
                      endcase
                      AluEnable     <= 1;
                      currentState  <= EXECUTE3;
                    end
                    EXECUTE3:
                    begin
                      AluX <= {8'h00, memDataR};
                      currentState  <= EXECUTE4;
                    end
                    EXECUTE4:
                    begin
                      memDataW      <= AluO[7:0];
                      RW            <= 1;
                      currentState  <= FETCH0;
                    end
                    endcase
                  end
                  else
                  begin
                  case (currentState)
                    EXECUTE1:
                    begin
                      AluX      <= {8'h00, CBInsZ == 3'b111 ? RegA : RegBankOut};
                      AluWriteA <= CBInsZ == 3'b111;
                      case (CBInsX)
                        2'b00: // ALUOP2[y] RG0[z]
                          AluOp <= CBInsY > 3 ? ALU_CB_BASE + CBInsY : ALU_RLC + CBInsY;
                        2'b01: // BIT Y, RG0[z]
                          AluOp <= {ALU_BIT[7:3], CBInsY};
                        2'b10: // RES Y, RG0[z]
                          AluOp <= {ALU_RES[7:3], CBInsY};
                        2'b11: // SET Y, RG0[z]
                          AluOp <= {ALU_SET[7:3], CBInsY};
                      endcase
                      AluEnable     <= 1;
                      currentState  <= EXECUTE2;
                    end
                    EXECUTE2:
                    begin
                      AluEnable    <= 0;
                      AluWriteA    <= 0;
                      if (CBInsZ != 3'b111) // A already written
                      begin
                        RegWriteEnable8 <= 1;
                        RegBankIn       <= AluO[7:0];
                      end
                      currentState      <= FETCH0;
                    end
                  endcase
                  end
                3'b110: // DI
                begin
                  HandleInterrupts  <= 0;
                  currentState      <= FETCH0;
                end
                3'b111: // EI
                begin
                  HandleInterrupts  <= 1;
                  currentState      <= FETCH0;
                end
                default: // TRAP UNDEFINED
                  currentState    <= TRAP;
              endcase
            end
            3'b100: // CALL {NZ, Z, NC, C}
            begin
              case (currentState)
              EXECUTE0:
              begin
                case (InsY[1:0])
                  2'b00:  // NZ
                  begin
                    currentState  <= !(RegF[ALU_FLAG_ZERO]) ? EXECUTE1   : FETCH0;
                    PC            <= !(RegF[ALU_FLAG_ZERO]) ? PC         : PC + 2;
                  end
                  2'b01: //  Z
                  begin
                    currentState  <= (RegF[ALU_FLAG_ZERO])  ? EXECUTE1   : FETCH0;
                    PC            <= (RegF[ALU_FLAG_ZERO])  ? PC         : PC + 2;
                  end
                  2'b10: // NC
                  begin
                    currentState  <= !(RegF[ALU_FLAG_CARRY]) ? EXECUTE1  : FETCH0;
                    PC            <= !(RegF[ALU_FLAG_CARRY]) ? PC        : PC + 2;
                  end
                  2'b11: //  C
                  begin
                    currentState  <= (RegF[ALU_FLAG_CARRY]) ? EXECUTE1   : FETCH0;
                    PC            <= (RegF[ALU_FLAG_CARRY]) ? PC         : PC + 2;
                  end
                endcase
              end
              EXECUTE1:
              begin
                currentInstruction  <= 8'b11001101;// Set to normal CALL a16
                currentState        <= EXECUTE0;
              end
              endcase
            end
            3'b101:
            begin
              if (InsY[0] == 0) // PUSH {BC, DE, HL, AF}
              begin
                case (currentState)
                  EXECUTE0: // Select Register
                  begin
                    if (InsY[2:1] != 2'b11) // If not AF
                      RegNum       <= (InsY[2:1] << 1);
                    SP            <= SPMinusOne;
                    currentState  <= EXECUTE1;
                  end
                  EXECUTE1: // Write first register
                  begin
                    memAddress    <= SP;
                    RW            <= 1;
                    SP            <= SPMinusOne;
                    memDataW      <= InsY[2:1] == 2'b11 ? RegA[7:0] : RegBankOut16[7:0];
                    currentState  <= EXECUTE2;
                  end
                  EXECUTE2: // Write last register
                  begin
                    memDataW      <= InsY[2:1] == 2'b11 ? {4'b0, RegF} : RegBankOut16[15:8];
                    memAddress    <= SP;
                    currentState  <= FETCH0;
                  end
                endcase
              end
              else if (InsY == 3'b001) // CALL a16
              begin
                // Read a16 into WZ
                // Save PC into [SP]
                // Jump to WZ
                case (currentState)
                  // Load a16
                  EXECUTE0:
                  begin
                    RegNum          <= REGNUM_Z;
                    RegBankIn       <= memDataR;
                    RegWriteEnable8 <= 1;
                    PC              <= MemAddressPlusOne;
                    memAddress      <= MemAddressPlusOne;
                    currentState    <= EXECUTE1;
                  end
                  EXECUTE1:
                  begin
                    PC              <= MemAddressPlusOne;
                    currentState    <= EXECUTE2; // Idle state
                  end
                  EXECUTE2:
                  begin
                    // Save to Z
                    RegNum          <= REGNUM_W;
                    RegBankIn       <= memDataR;
                    // Update PC
                    currentState    <= EXECUTE3;
                  end
                  EXECUTE3: // Stage SAFE TO CALL FROM OTHER STAGE - expect destiny at WZ
                  begin
                    // Disable Z write
                    RegWriteEnable8   <= 0;
                    RegWriteEnable16  <= 0; // From Interrupts

                    // Set Stack Pointer and address to SP-1 and write
                    SP              <= SPMinusOne;
                    memAddress      <= SPMinusOne;
                    RW              <= 1;
                    memDataW        <= PC[7:0];
                    currentState    <= EXECUTE4;
                  end
                  // Save PC into [SP], set PC
                  EXECUTE4:
                  begin
                    // Set dataOut to upper byte of PC and keep WriteEnable
                    memAddress      <= SPMinusOne;
                    memDataW        <= PC[15:7];
                    // Decrement Stack Pointer
                    SP              <= SPMinusOne;
                    // Jump to WZ (RegBankOut16)
                    PC              <= RegBankOut16;
                    currentState    <= FETCH0;
                  end
                endcase
              end
              else
                currentState <= TRAP; // UNDEF
            end
            3'b110:
            begin
              AluOp         <= InsY;
              AluX          <= RegA;
              AluY          <= memDataR;
              AluEnable     <= 1;
              AluWriteA     <= 1;
              PC            <= MemAddressPlusOne;
              currentState  <= FETCH0;
            end
            3'b111:
            begin
              // RESET VECTOR
                // Save PC into [SP]
                // Jump to 16'b0000000000YYY000
                case (currentState)
                  EXECUTE0:
                  begin
                    // Update PC
                    PC              <= MemAddressPlusOne;

                    // Set Stack Pointer and address to SP-1 and write
                    SP              <= SPMinusOne;
                    memAddress      <= SPMinusOne;
                    RW              <= 1;
                    memDataW        <= MemAddressPlusOne[7:0];

                    currentState    <= EXECUTE1;
                  end
                  // Save PC into [SP], set PC
                  EXECUTE1:
                  begin
                    // Set dataOut to upper byte of PC and keep WriteEnable
                    memAddress      <= SPMinusOne;
                    memDataW        <= PC[15:7];
                    // Decrement Stack Pointer
                    SP              <= SPMinusOne;
                    // Jump to 16'b0000000000YYY000
                    PC              <= {11'b000, InsY, 3'b000};
                    currentState    <= FETCH0;
                  end
                endcase
            end
            default:
              currentState <= TRAP;
          endcase
        end
      endcase
    end
  end
end

endmodule