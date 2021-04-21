
// Z - Zero Flag
// N - Subtract Flag
// H - Half Carry Flag
// C - Carry Flag

parameter ALU_FLAG_ZERO      = 3; // Z
parameter ALU_FLAG_SUB       = 2; // N
parameter ALU_FLAG_HALFCARRY = 1; // H
parameter ALU_FLAG_CARRY     = 0; // C

// ALU Operations

// Op Group 1
//ADD ADC SUB SBC AND XOR OR CP

parameter ALU_ADD       = 8'h00;
parameter ALU_ADC       = 8'h01;
parameter ALU_SUB       = 8'h02;
parameter ALU_SBC       = 8'h03;
parameter ALU_AND       = 8'h04;
parameter ALU_XOR       = 8'h05;
parameter ALU_OR        = 8'h06;
parameter ALU_CP        = 8'h07;

// Op group 2
//RLCA  RRCA  RLA RRA DAA CPL SCF CCF
parameter ALU_RLC       = 8'h10;
parameter ALU_RRC       = 8'h11;
parameter ALU_RL        = 8'h12;
parameter ALU_RR        = 8'h13;

parameter ALU_DAA       = 8'h14;
parameter ALU_CPL       = 8'h15;
parameter ALU_SCF       = 8'h16;
parameter ALU_CCF       = 8'h17;

// From Prefix CB
parameter ALU_CB_BASE   = 8'h20;
parameter ALU_SLA       = 8'h24;
parameter ALU_SRA       = 8'h25;
parameter ALU_SRL       = 8'h26;
parameter ALU_SWAP      = 8'h27;

parameter ALU_BIT       = 8'h30;
parameter ALU_RES       = 8'h40;
parameter ALU_SET       = 8'h50;

// 16 bit operations
parameter ALU_ADD16     = 8'h60;
