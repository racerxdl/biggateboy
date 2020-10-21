#!/usr/bin/env python3


FlagZero      = 1 << 3
FlagSub       = 1 << 2
FlagHalfCarry = 1 << 1
FlagCarry     = 1 << 0

# ALU Operations
OpOR    = 0x00
OpAND   = 0x01
OpXOR   = 0x02
OpCPL   = 0x03
OpADD   = 0x04
OpADC   = 0x05
OpSUB   = 0x06
OpSBC   = 0x07
OpRLC   = 0x08
OpRL    = 0x09
OpRRC   = 0x0a
OpRR    = 0x0b
OpSLA   = 0x0c
OpSRA   = 0x0d
OpSRL   = 0x0e
OpSWAP  = 0x0f
OpDAA   = 0x10
OpADD16 = 0x11

def Test(op, x=0, y=0, f=0, o=0, fresult=0):
  return {"op":op,"x": x,"y": y,"f":f,"o": o,"fresult" : fresult}

ALUTests = [
  # ADD
  Test(OpADD, x=    1,   y=    2, f=   0, o=     3,  fresult=0),                                     # [  0] No Carry, No Half Carry
  Test(OpADD, x=   15,   y=    2, f=   0, o=    17,  fresult=FlagHalfCarry),                         # [  1] No Carry, Half Carry
  Test(OpADD, x=65535,   y=    2, f=   0, o=     1,  fresult=FlagCarry | FlagHalfCarry),             # [  2] Carry, Half Carry
  Test(OpADD, x=65535,   y=    1, f=   0, o=     0,  fresult=FlagZero | FlagCarry | FlagHalfCarry),  # [  3] Carry, Half Carry, Zero

  # SUB
  Test(OpSUB, x=    1,   y=    2, f=   0, o= 65535,  fresult=FlagCarry | FlagHalfCarry | FlagSub),   # [  4] Carry, Half Carry
  Test(OpSUB, x=   16,   y=    2, f=   0, o=    14,  fresult=FlagHalfCarry| FlagSub),                # [  5] No Carry, Half Carry
  Test(OpSUB, x=65535,   y=    2, f=   0, o= 65533,  fresult=FlagSub),                               # [  6] No Carry, No Half Carry
  Test(OpSUB, x=    1,   y=    1, f=   0, o=     0,  fresult=FlagZero | FlagSub),                    # [  7] Zero

  # ADC
  Test(OpADC, x=    1,   y=    2, f=   0, o=     3,  fresult=0),                                     # [  8] No Carry Input, No Carry Output, No Half Carry
  Test(OpADC, x=   15,   y=    2, f=   0, o=    17,  fresult=FlagHalfCarry),                         # [  9] No Carry Input, No Carry Output, Half Carry
  Test(OpADC, x=65535,   y=    2, f=   0, o=     1,  fresult=FlagCarry | FlagHalfCarry),             # [ 10] No Carry Input, Carry Output, Half Carry
  Test(OpADC, x=    1,   y=    2, f=   1, o=     4,  fresult=0),                                     # [ 11] Carry Input, No Carry Output, No Half Carry
  Test(OpADC, x=   13,   y=    2, f=   1, o=    16,  fresult=FlagHalfCarry),                         # [ 12] Carry Input, No Carry Output, Half Carry
  Test(OpADC, x=65535,   y=    2, f=   1, o=     2,  fresult=FlagCarry | FlagHalfCarry),             # [ 13] Carry Input, Carry Output, Half Carry
  Test(OpADC, x=65535,   y=    0, f=   1, o=     0,  fresult=FlagZero | FlagCarry | FlagHalfCarry),  # [ 14] Carry Input, Carry Output, Half Carry Zero

  # SBC
  Test(OpSBC, x=    1,   y=    2, f=   0, o= 65535,  fresult=FlagCarry | FlagHalfCarry | FlagSub),   # [ 15] No Carry Input, No Carry Output, No Half Carry
  Test(OpSBC, x=   16,   y=    2, f=   0, o=    14,  fresult=FlagHalfCarry | FlagSub),               # [ 16] No Carry Input, No Carry Output, Half Carry
  Test(OpSBC, x=65535,   y=    2, f=   0, o= 65533,  fresult=FlagSub),                               # [ 17] No Carry Input, Carry Output, Half Carry
  Test(OpSBC, x=    1,   y=    2, f=   1, o= 65534,  fresult=FlagCarry | FlagHalfCarry | FlagSub),   # [ 18] Carry Input, No Carry Output, No Half Carry
  Test(OpSBC, x=   16,   y=    2, f=   1, o=    13,  fresult=FlagHalfCarry | FlagSub),               # [ 19] Carry Input, No Carry Output, Half Carry
  Test(OpSBC, x=65535,   y=    2, f=   1, o= 65532,  fresult=FlagSub),                               # [ 20] Carry Input
  Test(OpSBC, x=    1,   y=    0, f=   1, o=     0,  fresult=FlagSub | FlagZero),                    # [ 21] Carry Input, Zero

  # OR
  Test(OpOR,  x=    0,   y=    0, f=   0, o=     0,  fresult=FlagZero),                              # [ 22] Zero
  Test(OpOR,  x=65535,   y=    0, f=   0, o=   255,  fresult=0),                                     # [ 23]
  Test(OpOR,  x=    0,   y=65535, f=   0, o=   255,  fresult=0),                                     # [ 24]
  Test(OpOR,  x=    0,   y=65280, f=   0, o=     0,  fresult=FlagZero),                              # [ 25]
  Test(OpOR,  x=65280,   y=    0, f=   0, o=     0,  fresult=FlagZero),                              # [ 26]
]

def PackTest(op, x, y, f, o, fresult):
  '''
    OP(5), X(16), Y(16), F(4), O(16), FResult(4), Padding(3) == Total(64)
  '''
  # This doesnt need to be fast, so fuck it
  packedString = ""
  packedString += format(op     , "05b" ) # Operation   [  5 bits ]
  packedString += format(x      , "016b") # Operator X  [ 16 bits ]
  packedString += format(y      , "016b") # Operator Y  [ 16 bits ]
  packedString += format(f      , "04b" ) # Input Flag  [  4 bits ]
  packedString += format(o      , "016b") # Result      [ 16 bits ]
  packedString += format(fresult, "04b" ) # Result Flag [  4 bits ]
  packedString += format(0      , "03b" ) # Padding     [  3 bits ]

  return packedString.encode("ascii")

f = open("alu_tests.mem", "wb")

for i in range(len(ALUTests)):
  test = ALUTests[i]
  f.write(PackTest(**test))
  f.write(b"\r\n")

print("Number of tests: %d" % len(ALUTests))