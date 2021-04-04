module CPU (
  input  wire         clk,          // 4MHz clock
  input  wire         reset,
  output reg  [15:0]  memAddress,
  input  wire [7:0]   memDataR,
  output reg  [7:0]   memDataW,
  output reg          RW            // R/W (0 == Read, 1 == Write)
);

// Synchronous ALU
reg   [15:0]    AluX            = 0;
reg   [15:0]    AluY            = 0;
reg   [7:0]     AluOp           = 0;
reg             AluEnable       = 0;
reg             AluWriteA       = 0;

wire  [15:0]    RegA;
wire  [7:0]     RegF;
wire  [15:0]    AluO;

wire  [15:0]    MemAddressPlusOne   = memAddress + 1;
wire  [15:0]    MemAddressMinusOne  = memAddress - 1;

ALUSync alu(clk, reset, AluOp, AluX, AluY, AluEnable, AluWriteA, RegA, AluO, RegF);

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

localparam FETCH0   = 4'h0;
localparam FETCH1   = 4'h1;
localparam DECODE   = 4'h2;
localparam EXECUTE0 = 4'h3;
localparam EXECUTE1 = 4'h4;
localparam EXECUTE2 = 4'h5;
localparam EXECUTE3 = 4'h6;
localparam EXECUTE4 = 4'h7;
localparam EXECUTE5 = 4'h8;
localparam TRAP     = EXECUTE5 + 1;

localparam REGNUM_B = 4'h0;
localparam REGNUM_C = 4'h1;
localparam REGNUM_D = 4'h2;
localparam REGNUM_E = 4'h3;
localparam REGNUM_H = 4'h4;
localparam REGNUM_L = 4'h5;
localparam REGNUM_W = 4'h6;
localparam REGNUM_Z = 4'h7;


// ALU OPS
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

reg [7:0] currentState = FETCH0;
reg [7:0] currentInstruction = 8'h00;
reg [7:0] currentCBInstruction = 8'h00;

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
  end
  else
  begin
    if (currentState == FETCH0)
    begin
      memAddress        <= PC;
      RW                <= 0;
      currentState      <= FETCH1;
      RegWriteEnable8   <= 0;
      RegWriteEnable16  <= 0;
      AluWriteA         <= 0;
    end
    else if (currentState == FETCH1)
    begin
      PC                  <= MemAddressPlusOne;
      currentState        <= DECODE;
      memAddress          <= MemAddressPlusOne; // Pre-fetch
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
                      RegNum          <= REGNUM_L;
                      RegBankIn       <= memDataR;
                      currentState    <= EXECUTE2;
                    end
                    EXECUTE2:
                    begin
                      RegWriteEnable8 <= 0;
                      memAddress      <= RegBankOut16;
                      RW              <= 1;
                      currentState    <= FETCH0;
                    end
                  endcase
                end
                3'b010: // STOP
                  currentState <= TRAP; // TODO
                3'b011: // JR s8
                  currentState <= TRAP; // TODO
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
                currentState <= TRAP; // TODO
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
            // 3'b011:
            // 3'b100:
            // 3'b101:
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
            // 3'b111:
          endcase
        end
        2'b01: // Group 1
        begin
          currentState    <= FETCH0;
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
            // TODO
            currentState    <= TRAP;
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
            3'b011:
            begin
              case (InsY)
                3'b000: // JP a16
                  currentState    <= FETCH0; // TODO
                3'b001: // CB d8
                  if (currentState == EXECUTE0) // Common State
                  begin
                    PC                    <= MemAddressPlusOne;
                    currentCBInstruction  <= memDataR;
                    // Pre-select bank
                    if (memDataR[2:0] == 2'b10) // [HL]
                      RegNum <= REGNUM_H;
                    else if (memDataR[2:0] != 2'b11) // not A
                      RegNum <= memDataR[2:0];
                    currentState          <= EXECUTE1;
                  end
                  else if (CBInsY == 2'b10) // Memory Operation
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
                      AluX      <= {8'h00, CBInsZ == 2'b11 ? RegA : RegBankOut};
                      AluWriteA <= CBInsZ == RegA;
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
                      if (CBInsZ != 2'b11) // A already written
                      begin
                        RegWriteEnable8 <= 1;
                        RegBankIn       <= AluO[7:0];
                      end
                      currentState      <= FETCH0;
                    end
                  endcase
                  end
                3'b110: // DI
                  currentState    <= FETCH0; // TODO
                3'b111: // EI
                  currentState    <= FETCH0; // TODO
                default: // TRAP UNDEFINED
                  currentState <= TRAP;
              endcase
            end
          endcase
        end
      endcase
    end
  end
end

endmodule