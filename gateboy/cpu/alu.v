module ALU (
  input       [7:0]   op,     // Operation
  input       [15:0]  X,      // First Operand
  input       [15:0]  Y,      // Second Operand
  input       [3:0]   fIn,    // Flag Register Input  ( {Z,N,H,C} )

  output reg  [3:0]   fOut,   // Flag Register Output ( {Z,N,H,C} )
  output reg  [15:0]  O       // ALU Result
);

`include "aluops.v"

wire InputZero      = fIn[ALU_FLAG_ZERO];
wire InputCarry     = fIn[ALU_FLAG_CARRY];
wire InputSub       = fIn[ALU_FLAG_SUB];
wire InputHalfCarry = fIn[ALU_FLAG_HALFCARRY];

wire        IsBIT = op[7:4] == ALU_BIT[7:4];
wire        IsRES = op[7:4] == ALU_RES[7:4];
wire        IsSET = op[7:4] == ALU_SET[7:4];
wire [2:0]  ArgN  = op[2:0];

// Execute the operation
always @(*)
begin
  case(op)
    // These operations are 8 bit only
    ALU_OR:     O = {8'h00, X[7:0] | Y[7:0]};
    ALU_AND:    O = {8'h00, X[7:0] & Y[7:0]};
    ALU_XOR:    O = {8'h00, X[7:0] ^ Y[7:0]};
    ALU_CPL:    O = {8'h00, ~X[7:0]        };

    ALU_RLC:    O = {8'h00, X[6:0],      X[7]      };
    ALU_RL:     O = {8'h00, X[6:0],      InputCarry};
    ALU_RRC:    O = {8'h00, X[0],        X[7:1]    };
    ALU_RR:     O = {8'h00, InputCarry,  X[7:1]    };
    ALU_SLA:    O = {8'h00, X[6:0],      1'b0      };
    ALU_SRA:    O = {8'h00, X[7],        X[7:1]    };
    ALU_SRL:    O = {8'h00, 1'b0,        X[7:1]    };
    ALU_SWAP:   O = {8'h00, X[3:0],      X[7:4]    };

    // These operations can be either 8 or 16 bit.
    // So we always process as 16 bit

    ALU_ADD:    O = X + Y;
    ALU_ADD16:  O = X + Y;
    ALU_ADC:    O = X + Y + InputCarry;
    ALU_SUB:    O = X - Y;
    ALU_SBC:    O = X - Y - InputCarry;

    ALU_DAA: // That operation is crazy. It adjusts the register for BCD operation instead binary
    begin
      if (InputSub)
      begin
        // Subtracts 0x60 if has carry
        // Subtracts 0x06 if has half-carry
        O = {8'h00, X[7:0] - (InputCarry ? 8'h60 : 8'h00) - (InputHalfCarry ? 8'h06 : 8'h00)};
      end else begin
        // Adds 0x60 if has carry or > 0x99                   --> (InputCarry | X[7:0] > 8'h99 ? 8'h60 : 8'h00)
        // Adds 0x06 if has half carry or lower nibble > 0x09 --> (InputHalfCarry | X[3:0] > 4'h09 ? 8'h06 : 8'h00)
        O = {8'h00, X[7:0] + (InputCarry | X[7:0] > 8'h99 ? 8'h60 : 8'h00) + (InputHalfCarry | X[3:0] > 4'h9 ? 8'h06 : 8'h00)};
      end
    end
    ALU_CP:      O = X;
    ALU_SCF:     O = X;
    ALU_CCF:     O = X;
    default:
    begin
      if      (IsBIT) O = X;
      else if (IsRES) O = X & ~(1 << ArgN);
      else if (IsSET) O = X |  (1 << ArgN);
      else            O = 0;
    end
  endcase
end

// Set the output flags
reg [12:0] halfCarryHelper; // For ADD16 needs one nibble more than a byte
reg [16:0] carryHelper; // Needs one bit more than a 16 bit var

always @(*)
begin
  // Defaults
  fOut[ALU_FLAG_ZERO]       = InputZero;
  fOut[ALU_FLAG_SUB]        = InputSub;
  fOut[ALU_FLAG_HALFCARRY]  = 0;
  fOut[ALU_FLAG_CARRY]      = 0;

  case (op)
    ALU_ADD:
    begin
      // Calculate Half carry
      halfCarryHelper = ({1'b0, X[3:0]} + {1'b0, Y[3:0]});

      // Calculate Carry
      carryHelper     = ({1'b0, X[7:0]} + {1'b0, Y[7:0]});

      // Set flags
      fOut[ALU_FLAG_HALFCARRY] = halfCarryHelper[4];
      fOut[ALU_FLAG_CARRY]     = carryHelper[8];
      fOut[ALU_FLAG_SUB]       = 0;
      fOut[ALU_FLAG_ZERO]      = carryHelper[7:0] == 0;
    end
    ALU_ADD16:
    begin
      // Calculate Half carry
      halfCarryHelper = ({1'b0, X[11:0]} + {1'b0, Y[11:0]});

      // Calculate Carry
      carryHelper = ({1'b0, X} + {1'b0, Y});

      // Set flags
      fOut[ALU_FLAG_HALFCARRY] = halfCarryHelper[12];
      fOut[ALU_FLAG_CARRY]     = carryHelper[16];
      fOut[ALU_FLAG_SUB]       = 0;
    end
    ALU_ADC:
    begin
      // Calculate Half carry
      halfCarryHelper = ({1'b0, X[3:0]} + {1'b0, Y[3:0]} + InputCarry);

      // Calculate Carry
      carryHelper     = ({1'b0, X[7:0]} + {1'b0, Y[7:0]} + InputCarry);

      // Set flags
      fOut[ALU_FLAG_HALFCARRY] = halfCarryHelper[4];
      fOut[ALU_FLAG_CARRY]     = carryHelper[8];
      fOut[ALU_FLAG_SUB]       = 0;
      fOut[ALU_FLAG_ZERO]      = carryHelper[7:0] == 0;
    end
    ALU_SUB:
    begin
      // Calculate Half carry
      halfCarryHelper = ({1'b0, X[3:0]} - {1'b0, Y[3:0]});

      // Calculate Carry
      carryHelper     = ({1'b0, X[7:0]} - {1'b0, Y[7:0]});

      // Set flags
      fOut[ALU_FLAG_HALFCARRY] = halfCarryHelper[4];
      fOut[ALU_FLAG_CARRY]     = carryHelper[8];
      fOut[ALU_FLAG_SUB]       = 1;
      fOut[ALU_FLAG_ZERO]      = carryHelper[7:0] == 0;
    end
    ALU_SBC:
    begin
      // Calculate Half carry
      halfCarryHelper = ({1'b0, X[3:0]} - {1'b0, Y[3:0]} - InputCarry);

      // Calculate Carry
      carryHelper     = ({1'b0, X[7:0]} - {1'b0, Y[7:0]} - InputCarry);

      // Set flags
      fOut[ALU_FLAG_HALFCARRY] = halfCarryHelper[4];
      fOut[ALU_FLAG_CARRY]     = carryHelper[8];
      fOut[ALU_FLAG_SUB]       = 1;
      fOut[ALU_FLAG_ZERO]      = carryHelper[7:0] == 0;
    end

    ALU_OR:
    begin
      fOut[ALU_FLAG_HALFCARRY] = 0;
      fOut[ALU_FLAG_CARRY]     = 0;
      fOut[ALU_FLAG_SUB]       = 0;
      fOut[ALU_FLAG_ZERO]      = (X[7:0] | Y[7:0]) == 0;
    end
    ALU_XOR:
    begin
      fOut[ALU_FLAG_HALFCARRY] = 0;
      fOut[ALU_FLAG_CARRY]     = 0;
      fOut[ALU_FLAG_SUB]       = 0;
      fOut[ALU_FLAG_ZERO]      = (X[7:0] ^ Y[7:0]) == 0;
    end
    ALU_AND:
    begin
      fOut[ALU_FLAG_HALFCARRY] = 1;
      fOut[ALU_FLAG_CARRY]     = 0;
      fOut[ALU_FLAG_SUB]       = 0;
      fOut[ALU_FLAG_ZERO]      = (X[7:0] & Y[7:0]) == 0;
    end

    ALU_RLC:
    begin
      fOut[ALU_FLAG_ZERO]  = X[7:0] == 0; // That shift only will be zero if input is zero
      fOut[ALU_FLAG_CARRY] = X[7];
      fOut[ALU_FLAG_SUB]   = 0;
    end
    ALU_RL:
    begin
      fOut[ALU_FLAG_ZERO]  = X[6:0] == 0 | InputCarry;
      fOut[ALU_FLAG_CARRY] = X[7];
      fOut[ALU_FLAG_SUB]   = 0;
    end
    ALU_RRC:
    begin
      fOut[ALU_FLAG_ZERO]  = X[7:0] == 0; // That shift only will be zero if input is zero
      fOut[ALU_FLAG_CARRY] = X[0];
      fOut[ALU_FLAG_SUB]   = 0;
    end
    ALU_RR:
    begin
      fOut[ALU_FLAG_ZERO] = X[7:1] == 0 | InputCarry;
      fOut[ALU_FLAG_CARRY] = X[0];
      fOut[ALU_FLAG_SUB] = 0;
    end
    ALU_SLA:
    begin
      fOut[ALU_FLAG_ZERO] = X[6:0] == 0;
      fOut[ALU_FLAG_CARRY] = X[7];
      fOut[ALU_FLAG_SUB] = 0;
    end
    ALU_SRA:
    begin
      fOut[ALU_FLAG_ZERO] = X[7:1] == 0;
      fOut[ALU_FLAG_CARRY] = X[0];
      fOut[ALU_FLAG_SUB] = 0;
    end
    ALU_SRL:
    begin
      fOut[ALU_FLAG_ZERO] = X[7:1] == 0;
      fOut[ALU_FLAG_CARRY] = X[0];
      fOut[ALU_FLAG_SUB] = 0;
    end
    ALU_SWAP:
    begin
      fOut[ALU_FLAG_ZERO] = X[7:0] == 0;
      fOut[ALU_FLAG_CARRY] = 0;
      fOut[ALU_FLAG_SUB] = 0;
      fOut[ALU_FLAG_HALFCARRY] = 0;
    end
    ALU_DAA:      fOut[ALU_FLAG_CARRY] = !InputSub && X[7:0] > 8'h99;
    ALU_SCF:
    begin
      fOut[ALU_FLAG_SUB] = 0;
      fOut[ALU_FLAG_HALFCARRY] = 0;
      fOut[ALU_FLAG_CARRY] = 1;
    end
    ALU_CCF:
    begin
      fOut[ALU_FLAG_SUB] = 0;
      fOut[ALU_FLAG_HALFCARRY] = 0;
      fOut[ALU_FLAG_CARRY] = ~fIn[ALU_FLAG_CARRY]; // TODO
    end
    ALU_CP:
    begin
      fOut[ALU_FLAG_ZERO]  = X[7:0] == Y[7:0];
      fOut[ALU_FLAG_CARRY] = X[7:0] < Y[7:0];
      fOut[ALU_FLAG_SUB]   = 1;
      fOut[ALU_FLAG_HALFCARRY] = X[3:0] < Y[3:0];
    end
    default:
    begin
      if      (IsBIT)
      begin
        fOut[ALU_FLAG_ZERO] = X[ArgN] == 0;
        fOut[ALU_FLAG_SUB] = 0;
        fOut[ALU_FLAG_HALFCARRY] = 1;
      end
    end
  endcase
end

endmodule
