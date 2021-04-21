# Test Load/Store

1. Load test_load.gb
2. Reset the CPU and clear the memory
3. Run until PC == 0x14
    * Expect A == 10
    * Expect B == 11
    * Expect C == 12
    * Expect D == 13
    * Expect E == 14
    * Expect H == 15
    * Expect L == 16
4. Run until PC == 0x28
    * Expect memory[0xFF00] == 0x10
    * Expect memory[0xFF10] == 0x12
    * Expect memory[0xFF11] == 0x12
    * Expect memory[0xFF12] == 0x12
    * Expect memory[0xFF13] == 0x12
5. Run until PC == 0x36
    * Expect memory[0xFF10] == 0xF0
    * Expect memory[0xFF11] == 0xF0
    * Expect memory[0xFF12] == 0xF0
    * Expect memory[0xFF13] == 0xF0
6. Run until PC == 0x44
    * Expect B  == 0xFF
    * Expect C  == 0x20
    * Expect D  == 0xFF
    * Expect E  == 0x21
    * Expect H  == 0xFF
    * Expect L  == 0x22
    * Expect SP == 0xFF23
7. Run until PC == 0x50
    * Expect memory[0xFF20] == 0xF0
    * Expect memory[0xFF21] == 0xF1
    * Expect memory[0xFF22] == 0xF2
8. Run until PC == 0x54
    * Expect memory[0xFF80] == 0x23
    * Expect memory[0xFF81] == 0xFF
9. Run until PC == 0x5B
    * Expect B == 0xF0
    * Expect D == 0xF1
    * Expect H == 0xF2
10. Run until PC == 0x66
    * Expect memory[0xFF60] == 0x66
    * Expect A == 0x66
11. Run until PC == 0x6C
    * Expect H == 0xFF
    * Expect L == 0x10
12. Run until PC == 0x72
    * Expect H = 0xFF
    * Expect L = 0x05
13. Run until PC == 0x7B
    * Expect memory[0xFF80] == 0xFC
    * Expect A == 0xFC
14. Run until PC == 0x86
    * Expect memory[0x1000] == 0x88
    * Expect A == 0x88

