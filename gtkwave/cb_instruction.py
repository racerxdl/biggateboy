#!/usr/bin/env python3

import sys
import tempfile
import subprocess

regGroup0 = [
  "B", "C", "D", "E", "H", "L", "[HL]", "A"
]

aluOp0 = [
  "RLC", "RRC", "RL", "RR", "SLA", "SRA", "SWAP", "SRL"
]

def GetInstructionX00(y, z):
  return "%s %s" %(aluOp0[y], regGroup0[z])

def GetInstructionX01(y, z):
  return "BIT %d, %s" % (y, regGroup0[z])

def GetInstructionX10(y, z):
  return "RES %d, %s" % (y, regGroup0[z])

def GetInstructionX11(y, z):
  return "SET %d, %s" % (y, regGroup0[z])

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