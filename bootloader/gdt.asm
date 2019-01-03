; GDT start

gdt_start:

gdt_null:       ; null descritor
    dd  0x00    ; dd means double word (i.e. 4 bytes)
    dd  0x00

; code segment descriptor
; base=0x00, limit=0xfffff
; 1 flags: (present)1 (privilege)00 (descriptor type)1 -> 1001b
; type flags: (code)1 (conforming)0 (readable)1 (accessed)0 -> 1010b
; 2nd flags: (granularity)1 (32-bit default)1 (64-bit seg)0 (AVL)0 -> 1100b
gdt_code:       
    dw  0xffff      ; Limit (bits 0-15)
    dw  0x00        ; Base (bits 0-15)
    db  0x00        ; Base (bits 16-23)
    db  10011010b   ; 1st flags, type flags
    db  11001111b   ; 2nd flags, Limit (bits 16-19)
    db  0x00        ; Base (bits 24-31)

; data segment descriptor
; same as code semgent except for the type flags:
; type flags: (code)0 (expand down)0 (writable)1 (accessed)0 -> 0010b
gdt_data:       
    dw  0xffff      ; Limit (bits 0-15)
    dw  0x00        ; Base (bits 0-15)
    db  0x00        ; Base (bits 16-23)
    db  10010010b   ; 1st flags, type flags
    db  11001111b   ; 2nd flags, Limit (bits 16-19)
    db  0x00        ; Base (bits 24-31)

; put label to calculate size of gdt for descriptor
gdt_end:

gdt_desc:
    dw  gdt_end - gdt_start - 1 
    dd  gdt_start

CODE_SEG equ gdt_code - gdt_start

DATA_SEG equ gdt_data - gdt_start
