[bits 16]

; prints a string in real mode
; input:
;   bx - points to zero terminated string
print_string_rm:
    pusha           ; push all register values to stack

.loop:              ; loop over all chars in string
    mov al, [bx]    ; move single char at address bx to al

    ; if char at 'al' is null terminator -> finish
    test al, al
    jz .finish
    
    call put_char_rm

    ; let bx point to next character in string
    add bx, 0x01
    jmp .loop

.finish:            ; all characters printed -> return
    popa            ; restore original register values 
    ret             ; return


; prints a single character in real mode
; input:
;   al - character to print
put_char_rm:
    pusha           ; push all register values to stack
    mov ah, 0x0e    ; int=10/ah=0x0e -> BIOS output
    int 0x10        ; cause interrupt
    popa            ; restore original register values
    ret             ; return


; prints a new line in real mode
print_newline_rm:
    pusha           ; push all register values to stack
    mov al, 0x0a    ; new line feed
    call put_char_rm
    mov al, 0x0d    ; carriage return
    call put_char_rm
    popa            ; restore original register values
    ret             ; return
