[bits 32]
[extern main]
section .text
_start:
    call main
    jmp $
