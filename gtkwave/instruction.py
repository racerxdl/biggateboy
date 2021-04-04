#!/usr/bin/env python3

import sys
import tempfile
import subprocess

regGroup0 = [
  "B", "C", "D", "E", "H", "L", "[HL]", "A"
]

regGroup1 = [
  "BC", "DE", "HL", "SP"
]

regGroup2 = [
  "BC", "DE", "HL", "AF"
]

condGroup0 = [
  "NZ", "Z", "NC", "C"
]

aluOp0 = [
  "RLCA", "RRCA", "RLA", "RRA", "DAA", "CPL", "SCF", "CCF"
]

aluOp1 = [
  "ADD", "ADC", "SUB", "SBC", "AND", "XOR", "OR", "CP"
]

def GetInstructionX00(y, z):
  if y == 0 and z == 0:
    return "NOP"
  if y == 1 and z == 0:
    return "LD [a16], SP"
  if y == 2 and z == 0:
    return "STOP"
  if y == 3 and z == 0:
    return "JR s8"
  if y & 4 > 0 and z == 0:
    return "JR %s, s8" % condGroup0[y & 3]
  if y & 1 == 1 and z == 1:
    return "ADD HL, %s" % regGroup1[(y & 6) >> 1]
  if y & 1 == 0 and z == 1:
    return "LD %s, d16" % regGroup1[(y & 6) >> 1]

  if z == 2:
    if y == 0:
      return "LD [BC], A"
    elif y == 1:
      return "LD A, [BC]"
    elif y == 2:
      return "LD [DE], A"
    elif y == 3:
      return "LD A, [DE]"
    elif y == 4:
      return "LD [HL+], A"
    elif y == 5:
      return "LD A, [HL+]"
    elif y == 6:
      return "LD [HL-], A"
    elif y == 7:
      return "LD A, [HL-]"
  if z == 3:
    if y & 1 == 0:
      return "DEC %s" % regGroup1[(y & 6) >> 1]
    else:
      return "INC %s" % regGroup1[(y & 6) >> 1]
  if z == 4:
    return "INC %s" % regGroup0[y]
  if z == 5:
    return "DEC %s" % regGroup0[y]
  if z == 6:
    return "LD %s, d8" % regGroup0[y]
  if z == 7:
    return aluOp0[y]

  return "UNK"

def GetInstructionX01(y, z):
  if y == 6 and z == 6:
    return "HALT"

  return "LD %s, %s" % (regGroup0[y], regGroup0[z])

def GetInstructionX10(y, z):
  return "%s A, %s" % (aluOp1[y], regGroup0[z])

def GetInstructionX11(y, z):
  if z == 0:
    if y < 4:
      return "RET %s" % (condGroup0[y])

    if y == 4:
      return "LD [0xFF00 + a8], A"

    if y == 5:
      return "ADD SP, s8"

    if y == 6:
      return "LD A, [0xFF00 + a8]"

    if y == 7:
      return "LD HL, SP + r8"

  if z == 1:
    if y & 1 == 0:
      return "POP %s" % regGroup2[y >> 1]
    if y == 1:
      return "RET"
    if y == 3:
      return "RETI"
    if y == 5:
      return "JP HL"
    if y == 7:
      return "LD HL, SP"

  if z == 2:
    if y < 4:
      return "JP %s, a16" % condGroup0[y]
    if y == 4:
      return "LD [0xFF00 + C], A"
    if y == 5:
      return "LD [a16], A"
    if y == 6:
      return "LD A, [0xFF00 + C]"
    if y == 7:
      return "LD A, [a16]"

  if z == 3:
    if y == 0:
      return "JP a16"
    if y == 1:
      return "PREFIX CB"
    if y == 2:
      return "UNDEF"
    if y == 3:
      return "UNDEF"
    if y == 4:
      return "UNDEF"
    if y == 5:
      return "UNDEF"
    if y == 6:
      return "DI"
    if y == 7:
      return "EI"

  if z == 4:
    if y < 4:
      return "CALL %s, a16" % condGroup0[y]
    return "UNDEF"

  if z == 5:
    if y < 4:
      return "PUSH %s" % regGroup2[y]
    if y == 4:
      return "CALL a16"
    return "UNDEF"

  if z == 6:
    return "%s A, d8" % aluOp1[y]

  if z == 7:
    return "RST %d" % y

  return "---"

def GetInstructionName(v):
  x = (v & 0xC0) >> 6
  y = (v & 0x38) >> 3
  z = (v & 0x07) >> 0

  if x == 0:
    return GetInstructionX00(y, z)
  elif x == 1:
    return GetInstructionX01(y, z)
  elif x == 2:
    return GetInstructionX10(y, z)
  else:
    return GetInstructionX11(y, z)


def main(argv0, *args):
    fh_in = sys.stdin
    fh_out = sys.stdout

    while True:
        l = fh_in.readline()
        if not l:
            return 0

        if "x" in l:
            fh_out.write(l)
            fh_out.flush()
            continue

        ins = int(l, 16)
        fh_out.write(GetInstructionName(ins) + "\n")

        fh_out.flush()



if __name__ == '__main__':
  sys.exit(main(*sys.argv))