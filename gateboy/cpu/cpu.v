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
reg   [5:0]     AluOp           = 0;
reg             AluEnable       = 0;
reg             AluWriteA       = 0;

wire  [15:0]    RegA;
wire  [7:0]     RegF;

ALUSync alu(clk, reset, AluOp, AluX, AluY, AluEnable, AluWriteA, RegA, RegF);

// Register Bank
reg   [7:0]     RegBankIn       = 0;
wire  [7:0]     RegBankOut;
wire  [15:0]    RegBankOut16;
reg   [2:0]     RegNum          = 0;
reg             RegWriteEnable  = 0;
wire [15:0]     StackPointer;

RegisterBank regBank(clk, reset, RegBankIn, RegBankOut, RegBankOut16, StackPointer, RegNum, RegWriteEnable);

// Program Counter
reg  [15:0]   PCDataIn      = 0;
wire [15:0]   PCDataOut;
reg           PCWriteEnable = 0; // 1 => WRITE, 0 => READ
reg           PCCountEnable = 0; // 1 => COUNT UP, 0 => STOPPED
reg           PCWriteAddTo  = 0; // 1 => Add to PC, 0 => Set to PC

// Our device under test
ProgramCounter dut(clk, reset, PCDataIn, PCDataOut, PCWriteEnable, PCWriteAddTo, PCCountEnable);

localparam FETCH0   = 4'h0;
localparam FETCH1   = 4'h1;
localparam DECODE   = 4'h2;
localparam EXECUTE0 = 4'h3;
localparam EXECUTE1 = 4'h4;
localparam EXECUTE2 = 4'h5;
localparam EXECUTE3 = 4'h6;

reg [5:0] currentState = FETCH0;
reg [7:0] currentInstruction = 8'h00;

wire [1:0] InsX = currentInstruction[7:6];
wire [2:0] InsY = currentInstruction[5:3];
wire [2:0] InsZ = currentInstruction[2:0];

always @(posedge clk)
begin
  if (reset)
  begin
    // ALU Reset
    AluX                <= 0;
    AluY                <= 0;
    AluOp               <= 0;
    AluEnable           <= 0;

    // Register Bank Reset
    RegBankIn           <= 0;
    RegNum              <= 0;
    RegWriteEnable      <= 0;

    // Bus Reset
    memDataW            <= 0;
    RW                  <= 0;
    memAddress          <= 0;

    // Program Counter
    PCDataIn            <= 0;
    PCCountEnable       <= 0;
    PCWriteAddTo        <= 0;

    // State Machine
    currentState        <= FETCH0;
    currentInstruction  <= 0;
  end
  else
  begin
    if (currentState == FETCH0)
    begin
      memAddress      <= PCDataOut;
      PCCountEnable   <= 1;
      RW              <= 0;
      currentState    <= FETCH1;
      RegWriteEnable  <= 0;
    end
    else if (currentState == FETCH1)
    begin
      PCCountEnable       <= 0;
      currentState        <= DECODE;
      memAddress          <= PCDataOut + 1; // Pre-fetch
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
                  currentState <= FETCH0; // TODO
                3'b010: // STOP
                  currentState <= FETCH0; // TODO
                3'b011: // JR s8
                  currentState <= FETCH0; // TODO
                3'b1xx: // JR {NZ, Z, NC, C}, s8
                  currentState <= FETCH0; // TODO
              endcase
            end
            3'b001:
            begin
              if (InsY[0]) // ADD HL, {BC, DE, HL, SP}
              begin
                currentState <= FETCH0; // TODO
              end
              else          // LD {BC, DE, HL, SP}, d16
              begin
                case (currentState)
                  EXECUTE0:
                  begin
                    PCCountEnable   <= 1;
                    currentState    <= EXECUTE1;
                    memAddress      <= PCDataOut + 1;
                  end
                  EXECUTE1:
                  begin
                    PCCountEnable   <= 1;
                    RegNum          <= InsY[2:1] << 1; // BC, DE, HL, SP
                    RegWriteEnable  <= 1;
                    RegBankIn       <= memDataR;
                    memAddress      <= PCDataOut + 1;
                    currentState    <= EXECUTE2;
                  end
                  EXECUTE2:
                  begin
                    RegNum          <= RegNum + 1; // BC, DE, HL, SP
                    RegBankIn       <= memDataR;
                    currentState    <= FETCH0;
                    PCCountEnable   <= 0;
                  end
                endcase
              end
            end
            // 3'b010:
            // 3'b011:
            // 3'b100:
            // 3'b101:
            // 3'b110:
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
            currentState    <= FETCH0;
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
          currentState    <= FETCH0;
        end
      endcase
    end
  end
end

endmodule