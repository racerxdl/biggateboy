#!/usr/bin/env python3

import sys
import tempfile
import subprocess

states = {
    0: "FETCH0",
    1: "FETCH1",
    2: "DECODE",
    3: "EXECUTE0",
    4: "EXECUTE1",
    5: "EXECUTE2",
    6: "EXECUTE3",
    7: "EXECUTE4",
    8: "EXECUTE5"
}

lastState = -1
for i in states:
    if lastState < i:
        lastState = i

states[lastState + 1] = "TRAP"

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

        state = int(l, 16)
        if state in states:
          fh_out.write("%s\n" % states[state])
        else:
          fh_out.write(l)

        fh_out.flush()



if __name__ == '__main__':
  sys.exit(main(*sys.argv))