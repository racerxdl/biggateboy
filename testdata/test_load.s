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
  NOP
  NOP
  NOP
  NOP
  NOP

mem:
  LD H, $FF
  LD L, $00
  LD [HL], $10
  NOP
  LD H, $FF
  LD L, $10
  LD A, $12
  LD [HL+], A
  LD [HL+], A
  LD [HL+], A
  LD [HL+], A
  LD [HL+], A
  NOP
  NOP
  NOP
  LD L, $14
  LD A, $F0
  LD [HL-], A
  LD [HL-], A
  LD [HL-], A
  LD [HL-], A
  LD [HL-], A
  NOP
  NOP
  NOP
  NOP