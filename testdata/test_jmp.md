# Test jmp

1. Load test_load.gb
2. Reset the CPU and clear the memory
3. Run until PC == 0x0C
    * Expect A == 0x02
4. Run until PC == 0x1F
    * Expect A == 0x02
5. Run until PC == 0x27
    * Expect A == 0x03
6. Run until PC == 0x34
    * Expect A == 0x01
7. Set Zero Flag
8. Run until PC == 0x48
    * Expect A == 0x01
9. Unset Zero Flag
10. Set Carry Flag
11. Run until PC == 0x55
    * Expect A == 0x01
12. Unset Carry Flag
13. Set Zero Flag 
14. Run until PC == 0x6D
    * Expect A == 0x01
15. Unset Zero Flag
16. Set Carry Flag 
17. Run until PC == 0x7C
    * Expect A == 0x01
