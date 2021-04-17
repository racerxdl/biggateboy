# Test Call / RET

1. Load test_load.gb
2. Reset the CPU and clear the memory
3. Run until PC == 0x11
    * Expect memory[cpu.SP+0] == 0x00
    * Expect memory[cpu.SP+1] == 0x0A
4. Run until PC == 0x0D
    * Expect A == 0x01
    * Expect B == 0x01
5. Run until PC == 0x1A
6. Set Flag Zero
7. Run until PC == 0x1E
    * Expect A == 0x00
8. Run until PC == 0x24
    * Expect A == 0x01
9. Unset Flag Zero
10. Set Flag Carry
11. Run until PC == 0x28
    * Expect A == 0x01
12. Run until PC == 0x2D
    * Expect A == 0x02
13. Unset Flag Zero
14. Unset Flag Carry
15. Run until PC = 0x4C
    * Expect A == 0x01
    * Expect B == 0x00
16. Set Flag Zero
17. Run until PC == 0x57
    * Expect A == 0x02
    * Expect B == 0x00
18. Unset Flag Zero, Unset Flag Carry
19. Run until PC == 0x62
    * Expect A == 0x01
    * Expect B == 0x00
20. Set Flag Carry
21. Run until PC == 0x6D
    * Expect A == 0x02
    * Expect B == 0x00
