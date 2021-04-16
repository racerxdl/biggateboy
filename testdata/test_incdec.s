SECTION "Byte", ROM0
main:
  LD A, $10
  LD B, $11
  LD C, $12
  LD D, $13
  LD E, $14
  LD H, $15
  LD L, $16
  NOP
  INC A
  INC B
  INC C
  INC D
  INC E
  INC H
  INC L
  NOP
  DEC A
  DEC B
  DEC C
  DEC D
  DEC E
  DEC H
  DEC L
  NOP
  LD BC, $1000
  LD DE, $2000
  LD HL, $3000
  LD SP, $4000
  DEC BC
  DEC DE
  DEC HL
  DEC SP
  NOP
