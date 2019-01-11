[bits 32]
VIDEO_MEMORY equ 0xb8000
WHITE_ON_BLACK equ 0x0f

; prints a string in protected mode
; input:
;   - bx - points to a null terminated string
print_string_pm:
    pusha
    mov edx, VIDEO_MEMORY

.loop:
    mov al, [ebx]
    mov ah, WHITE_ON_BLACK

    ; if char is null it means end of string
    ; jump to .done and return
    cmp al, 0
    je .done

    mov [edx], ax
    
    add ebx, 1  ; let ebx point to next character
    
    ; text mode memory takes 2 bytes for every character
    ; one for the character itself
    ; and one for attribute (character color on background)
    ; add 2 to edx to print the next character
    add edx, 2

    ; repeat for next character
    jmp .loop

.done:
    popa
    ret
