:loop
nasm -f elf ttt_main.asm
C:\MinGW\bin\gcc ttt_main.o -s -nostartfiles -o release\game -LC:\Windows\System32 -luser32 -lkernel32
del ttt_main.o
pause
cls
goto loop

