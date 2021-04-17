SECTION "Byte", ROM0
main:
  LD SP, $FFF0
  LD A, $00
  LD B, $00
  CALL routine0
  LD B, $01
  NOP
  JR cont

routine0:
  INC A
  NOP
  NOP
  RET

cont:
  LD A, $00
  LD B, $00
  NOP
  NOP         ; Expect the simulator to set Zero Flag
  CALL NZ, routine0
  NOP
  NOP
  CALL Z, routine0
  NOP
  NOP         ; Expect the simulator to set Carry Flag
  CALL NC, routine0
  NOP
  NOP
  CALL C, routine0
  NOP
  NOP
  JR cont1

carrytest:
  LD A, $01
  RET NC
  LD A, $02
  RET C
  STOP  ; PROBLEM

zerotest:
  LD A, $01
  RET NZ
  LD A, $02
  RET Z
  STOP  ; PROBLEM

cont1:
  NOP
  NOP  ; Expect simulator to reset all flags
  LD A, $00
  LD B, $01
  CALL zerotest
  LD B, $00
  NOP
  NOP  ; Expect simulator to set zero
  LD A, $00
  LD B, $01
  CALL zerotest
  LD B, $00
  NOP
  NOP  ; Expect simulator to reset all flags
  LD A, $00
  LD B, $01
  CALL carrytest
  LD B, $00
  NOP
  NOP ; Expect simulator to set carry
  LD A, $00
  LD B, $01
  CALL carrytest
  LD B, $00
  NOP
  NOP
  NOP
  NOP
