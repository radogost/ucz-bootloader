[bits 16]

; prints a string
; input:
;   bx - points to zero terminated string
print_string:
    pusha           ; push all register values to stack

.loop:              ; loop over all chars in string
    mov al, [bx]    ; move single char at address bx to al

    ; if char at 'al' is null terminator -> finish
    test al, al
    jz .finish
    
    call print_char ; print this char
    add bx, 0x01    ; let bx point to next character in string
    jmp .loop

.finish:            ; all characters printed -> return
    popa            ; restore original register values 
    ret             ; return


; prints a single character
; input:
;   al - character to print
print_char:
    pusha           ; push all register values to stack
    mov ah, 0x0e    ; int=10/ah=0x0e -> BIOS output
    int 0x10        ; cause interrupt
    popa            ; restore original register values
    ret             ; return


; prints a new line
print_newline:
    pusha           ; push all register values to stack
    mov al, 0x0a    ; new line feed
    call print_char
    mov al, 0x0d    ; carriage return
    call print_char
    popa            ; restore original register values
    ret             ; return


; prints a hex number
; input:
;   bx - number to print
print_hex:
    pusha           ; push all register values to stack
    ; print '0x' first
    mov al, '0' 
    call print_char
    mov al, 'x'
    call print_char

    mov cx, 4       ; print 4 times single char [0-9a-f]

.loop:
    ; get 4 highest bits of bx
    mov al, bh
    shr al, 4

    ; if number in al to print < 10:
    ;   jump to .print_char
    cmp al, 0xa
    jl .print_char

    ; .print_char will add '0' to obtain ascii value
    ; so '0' needs to be removed
    ; also, al is greater or equal than 10, hence subtract 10
    ; to obtain correct ascii value
    add al, 'a' - 0xa - '0'

.print_char:
    add al, '0'     ; get ascii value of char in al
    call print_char

    ; shift by 4 bits to left to remove the 4 highest bits
    shl bx, 4
    loop .loop

.finish:
    popa            ; restore original register values
    ret             ; return
