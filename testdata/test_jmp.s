SECTION "Byte", ROM0
main:
  LD A, $00
  JP branch0
  LD A, $01
  NOP

branch0:
  LD A, $02
  NOP
  NOP
  LD A, $00
  NOP
  JR branch1
  LD A, $01
  NOP
  NOP

branch2:
  LD A, $03
  JR branch3
  NOP
  NOP

branch1:
  LD A, $02
  NOP
  NOP
  JR branch2
  LD A, $08
  NOP
  NOP

branch3:
  NOP
  LD A, $00
  LD HL, branch4
  JP HL
  NOP
  LD A, $FF
  NOP

branch4:
  LD A, $01
  NOP
  NOP

