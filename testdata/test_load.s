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
  LD BC, $FF20
  LD DE, $FF21
  LD HL, $FF22
  LD SP, $FF23
  NOP
  LD A, $F0
  LD [BC], A
  NOP
  LD A, $F1
  LD [DE], A
  NOP
  LD A, $F2
  LD [HL], A
  NOP
  LD [$FF80], SP
  NOP
  LD A, [BC]
  LD B, A     ; Should be F0
  LD A, [DE]
  LD D, A     ; Should be F1
  LD A, [HL]
  LD H, A     ; Should be F2
  NOP
  NOP
  NOP
  LD A, $66
  LD [$FF00 + $60], A
  LD A, $80
  LD A, [$FF00 + $60]
  NOP
  LD SP, $FF00
  LD HL, SP + $10
  NOP
  LD SP, $FF0A
  LD HL, SP + -5
  NOP
  LD C, $80
  LD A, $FC
  LD [$FF00 + C], A
  LD A, $00
  LD A, [$FF00 + C]
  NOP
  LD A, $88
  LD [$1000], A
  LD A, $FF
  LD A, [$1000]
  NOP