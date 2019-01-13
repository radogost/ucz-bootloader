;
; A simple bootloader
;
[bits 16]

section .text

global _start

_start:

boot:
    mov bp, 0x8000      ; move stack out of the way

; enable A20 line
enable_a20:
    in al, 0x92
    or al, 0x02
    out 0x92, al

    mov bx, UCZ_OS_NAME
    call print_string_rm
    call print_newline_rm

; switch to protected mode
switch_to_pm: 
    cli                 ; switch off interrupts
    lgdt [gdt_desc]     ; load global descriptor table

    ; make switch to protected mode by enabling first bit of cr0
    ; however, can't be set directly
    ; therefore load to eax first, set first bit and load it back
    mov eax, cr0
    or eax, 0x01
    mov cr0, eax

    ; make far jump to our 32-bit code
    jmp CODE_SEG:init_pm

[bits 32]
[extern boot_main]
init_pm:

    ; in protected mode old segments are meaningless
    ; point segment registers to data selector defined in GDT
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; update stack position
    mov ebp, 0x9000
    mov esp, ebp
    
    call load_kernel

    mov ebx, [BOOT_MAIN_ERROR]
    call print_string_pm

jmp $

%include "print_rm.asm"
%include "print_pm.asm"
%include "gdt.asm"
%include "load_kernel.asm"


UCZ_OS_NAME db "uczOS loader", 0
BOOT_MAIN_ERROR db "boot main error", 0

; Bootsector padding
times 510-($-$$) db 0
dw 0xaa55
