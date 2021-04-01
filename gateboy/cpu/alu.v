module ALU (
  input       [5:0]   op,     // Operation
  input       [15:0]  X,      // First Operand
  input       [15:0]  Y,      // Second Operand
  input       [3:0]   fIn,    // Flag Register Input  ( {Z,N,H,C} )

  output reg  [3:0]   fOut,   // Flag Register Output ( {Z,N,H,C} )
  output reg  [15:0]  O       // ALU Result
);

// Z - Zero Flag
// N - Subtract Flag
// H - Half Carry Flag
// C - Carry Flag

localparam FlagZeroBit      = 3; // Z
localparam FlagSubBit       = 2; // N
localparam FlagHalfCarryBit = 1; // H
localparam FlagCarryBit     = 0; // C

// ALU Operations

// Op Group 1
//ADD ADC SUB SBC AND XOR OR CP

parameter ADD       = 6'h00;
parameter ADC       = 6'h01;
parameter SUB       = 6'h02;
parameter SBC       = 6'h03;
parameter AND       = 6'h04;
parameter XOR       = 6'h05;
parameter OR        = 6'h06;
parameter CP        = 6'h07;

// Op group 2
//RLCA  RRCA  RLA RRA DAA CPL SCF CCF
parameter RLC       = 6'h08;
parameter RRC       = 6'h09;
parameter RL        = 6'h0a;
parameter RR        = 6'h0b;
parameter DAA       = 6'h0c;
parameter CPL       = 6'h0d;
parameter SCF       = 6'h0e;
parameter CCF       = 6'h0f;

// From Prefix CB
parameter SLA       = 6'h10;
parameter SRA       = 6'h11;
parameter SRL       = 6'h12;
parameter SWAP      = 6'h13;

// 16 bit operations
parameter ADD16     = 6'h20;

wire InputZero      = fIn[FlagZeroBit];
wire InputCarry     = fIn[FlagCarryBit];
wire InputSub       = fIn[FlagSubBit];
wire InputHalfCarry = fIn[FlagHalfCarryBit];

// Execute the operation
always @(*)
begin
  case(op)
    // These operations are 8 bit only
    OR:     O = {8'h00, X[7:0] | Y[7:0]};
    AND:    O = {8'h00, X[7:0] & Y[7:0]};
    XOR:    O = {8'h00, X[7:0] ^ Y[7:0]};
    CPL:    O = {8'h00, ~X[7:0]        };

    RLC:    O = {8'h00, X[6:0],      X[7]      };
    RL:     O = {8'h00, X[6:0],      InputCarry};
    RRC:    O = {8'h00, X[0],        X[7:1]    };
    RR:     O = {8'h00, InputCarry,  X[7:1]    };
    SLA:    O = {8'h00, X[6:0],      1'b0      };
    SRA:    O = {8'h00, X[7],        X[7:1]    };
    SRL:    O = {8'h00, 1'b0,        X[7:1]    };
    SWAP:   O = {8'h00, X[3:0],      X[7:4]    };

    // These operations can be either 8 or 16 bit.
    // So we always process as 16 bit

    ADD:    O = X + Y;
    ADD16:  O = X + Y;
    ADC:    O = X + Y + InputCarry;
    SUB:    O = X - Y;
    SBC:    O = X - Y - InputCarry;

    DAA: // That operation is crazy. It adjusts the register for BCD operation instead binary
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
    CP:      O = X;
    SCF:     O = X;
    CCF:     O = X;
    default: O = 0;
  endcase
end

// Set the output flags
reg [12:0] halfCarryHelper  = 0; // For ADD16 needs one nibble more than a byte
reg [16:0] carryHelper      = 0; // Needs one bit more than a 16 bit var

always @(*)
begin
  // Defaults
  fOut[FlagZeroBit]       = InputZero;
  fOut[FlagSubBit]        = InputSub;
  fOut[FlagHalfCarryBit]  = 0;
  fOut[FlagCarryBit]      = 0;

  case (op)
    ADD:
    begin
      // Calculate Half carry
      halfCarryHelper = ({1'b0, X[3:0]} + {1'b0, Y[3:0]});

      // Calculate Carry
      carryHelper     = ({1'b0, X[7:0]} + {1'b0, Y[7:0]});

      // Set flags
      fOut[FlagHalfCarryBit] = halfCarryHelper[4];
      fOut[FlagCarryBit]     = carryHelper[8];
      fOut[FlagSubBit]       = 0;
      fOut[FlagZeroBit]      = carryHelper[7:0] == 0;
    end
    ADD16:
    begin
      // Calculate Half carry
      halfCarryHelper = ({1'b0, X[11:0]} + {1'b0, Y[11:0]});

      // Calculate Carry
      carryHelper = ({1'b0, X} + {1'b0, Y});

      // Set flags
      fOut[FlagHalfCarryBit] = halfCarryHelper[12];
      fOut[FlagCarryBit]     = carryHelper[16];
      fOut[FlagSubBit]       = 0;
    end
    ADC:
    begin
      // Calculate Half carry
      halfCarryHelper <= ({1'b0, X[3:0]} + {1'b0, Y[3:0]} + InputCarry);

      // Calculate Carry
      carryHelper     <= ({1'b0, X[7:0]} + {1'b0, Y[7:0]} + InputCarry);

      // Set flags
      fOut[FlagHalfCarryBit] = halfCarryHelper[4];
      fOut[FlagCarryBit]     = carryHelper[8];
      fOut[FlagSubBit]       = 0;
      fOut[FlagZeroBit]      = carryHelper[7:0] == 0;
    end
    SUB:
    begin
      // Calculate Half carry
      halfCarryHelper <= ({1'b0, X[3:0]} - {1'b0, Y[3:0]});

      // Calculate Carry
      carryHelper     <= ({1'b0, X[7:0]} - {1'b0, Y[7:0]});

      // Set flags
      fOut[FlagHalfCarryBit] = halfCarryHelper[4];
      fOut[FlagCarryBit]     = carryHelper[8];
      fOut[FlagSubBit]       = 1;
      fOut[FlagZeroBit]      = carryHelper[7:0] == 0;
    end
    SBC:
    begin
      // Calculate Half carry
      halfCarryHelper <= ({1'b0, X[3:0]} - {1'b0, Y[3:0]} - InputCarry);

      // Calculate Carry
      carryHelper     <= ({1'b0, X[7:0]} - {1'b0, Y[7:0]} - InputCarry);

      // Set flags
      fOut[FlagHalfCarryBit] = halfCarryHelper[4];
      fOut[FlagCarryBit]     = carryHelper[8];
      fOut[FlagSubBit]       = 1;
      fOut[FlagZeroBit]      = carryHelper[7:0] == 0;
    end

    OR:
    begin
      fOut[FlagHalfCarryBit] = 0;
      fOut[FlagCarryBit]     = 0;
      fOut[FlagSubBit]       = 0;
      fOut[FlagZeroBit]      = (X[7:0] | Y[7:0]) == 0;
    end
    XOR:
    begin
      fOut[FlagHalfCarryBit] = 0;
      fOut[FlagCarryBit]     = 0;
      fOut[FlagSubBit]       = 0;
      fOut[FlagZeroBit]      = (X[7:0] ^ Y[7:0]) == 0;
    end
    AND:
    begin
      fOut[FlagHalfCarryBit] = 1;
      fOut[FlagCarryBit]     = 0;
      fOut[FlagSubBit]       = 0;
      fOut[FlagZeroBit]      = (X[7:0] & Y[7:0]) == 0;
    end

    RLC:
    begin
      fOut[FlagZeroBit]  = X[7:0] == 0; // That shift only will be zero if input is zero
      fOut[FlagCarryBit] = X[7];
      fOut[FlagSubBit]   = 0;
    end
    RL:
    begin
      fOut[FlagZeroBit]  = X[6:0] == 0 | InputCarry;
      fOut[FlagCarryBit] = X[7];
      fOut[FlagSubBit]   = 0;
    end
    RRC:
    begin
      fOut[FlagZeroBit]  = X[7:0] == 0; // That shift only will be zero if input is zero
      fOut[FlagCarryBit] = X[0];
      fOut[FlagSubBit]   = 0;
    end
    RR:
    begin
      fOut[FlagZeroBit] = X[7:1] == 0 | InputCarry;
      fOut[FlagCarryBit] = X[0];
      fOut[FlagSubBit] = 0;
    end
    SLA:
    begin
      fOut[FlagZeroBit] = X[6:0] == 0;
      fOut[FlagCarryBit] = X[7];
      fOut[FlagSubBit] = 0;
    end
    SRA:
    begin
      fOut[FlagZeroBit] = X[7:1] == 0;
      fOut[FlagCarryBit] = X[0];
      fOut[FlagSubBit] = 0;
    end
    SRL:
    begin
      fOut[FlagZeroBit] = X[7:1] == 0;
      fOut[FlagCarryBit] = X[0];
      fOut[FlagSubBit] = 0;
    end
    SWAP:
    begin
      fOut[FlagZeroBit] = X[7:0] == 0;
      fOut[FlagCarryBit] = 0;
      fOut[FlagSubBit] = 0;
      fOut[FlagHalfCarryBit] = 0;
    end
    DAA:      fOut[FlagCarryBit] = !InputSub && X[7:0] > 8'h99;
    default:  fOut[FlagCarryBit] = 0;
    SCF:
    begin
      fOut[FlagSubBit] = 0;
      fOut[FlagHalfCarryBit] = 0;
      fOut[FlagCarryBit] = 1;
    end
    CCF:
    begin
      fOut[FlagSubBit] = 0;
      fOut[FlagHalfCarryBit] = 0;
      fOut[FlagCarryBit] = ~fIn[FlagCarryBit]; // TODO
    end
    CP:
    begin
      fOut[FlagZeroBit] = X[7:0] == X[7:0];
      fOut[FlagCarryBit] = X[7:0] < X[7:0];
      fOut[FlagSubBit] = 1;
      fOut[FlagHalfCarryBit] = X[3:0] < X[3:0];
    end
  endcase
end

endmodule
