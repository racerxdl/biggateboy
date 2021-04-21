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
  LD A, $00  ; Expect simulator to set Z flag
  JR NZ, branchn0
  JR Z,  branch5
  NOP
  NOP
  STOP

branchn0:
  LD A, $FF
  NOP
  STOP
  NOP

branch5:
  LD A, $01
  NOP

  LD A, $00  ; Expect simulator to set C flag
  JR NC, branchn0
  JR C,  branch6
  NOP
  NOP
  STOP

branch6:
  LD A, $01
  NOP
  NOP
  NOP
  NOP

;--------
  LD A, $00  ; Expect simulator to set Z flag
  JP NZ, branchn1
  JP Z,  branch7
  NOP
  NOP
  STOP

branchn1:
  LD A, $FF
  NOP
  STOP
  NOP

branch7:
  LD A, $01
  NOP

  LD A, $00  ; Expect simulator to set C flag
  JP NC, branchn1
  JP C,  branch8
  NOP
  NOP
  STOP

branch8:
  LD A, $01
  NOP
  NOP
  NOP
