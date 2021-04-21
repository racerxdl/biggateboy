# Test INC/DEC

1. Load test_incdec.gb
2. Reset the CPU and clear the memory
3. Run until PC = 0x18
    * Expect A = 11
    * Expect B = 12
    * Expect C = 13
    * Expect D = 14
    * Expect E = 15
    * Expect H = 16
    * Expect L = 17
4. Run until PC = 0x20
    * Expect A = 10
    * Expect B = 11
    * Expect C = 12
    * Expect D = 13
    * Expect E = 14
    * Expect H = 15
    * Expect L = 16
5.  Run until PC = 0x31
    * Expect B  = 0x0F
    * Expect C  = 0xFF
    * Expect D  = 0x1F
    * Expect E  = 0xFF
    * Expect H  = 0x2F
    * Expect L  = 0xFF
    * Expect SP = 0x3FFF

