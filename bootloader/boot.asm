;
; A simple bootloader
;
[org 0x7c00]            ; BIOS will load bootloader at 0x7c00
KERNEL_OFFSET equ 0x1000

[bits 16]
boot:
    ; BIOS stores boot drive in dl
    ; store this for later
    mov [BOOT_DRIVE], dl
    mov bp, 0x8000      ; move stack out of the way

    mov bx, UCZ_OS_NAME
    call print_string
    call print_newline

load_kernel:
    ; setup parameters for disk load routine
    ; load first 15 sectors
    mov bx, KERNEL_OFFSET
    mov dh, 15
    mov dl, [BOOT_DRIVE]
    call disk_load

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

    ; jump to the address of loaded kernel
    call KERNEL_OFFSET

jmp $

%include "print.asm"
%include "disk_load.asm"
%include "gdt.asm"


UCZ_OS_NAME db "uczOS loader"
BOOT_DRIVE  db 0

; Bootsector padding
times 510-($-$$) db 0
dw 0xaa55
