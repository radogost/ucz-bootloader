[bits 32]

; address where kernel header will be loaded
KERNEL_HEADER_ADDRESS equ 0x10000

; sector size is 512 bytes
SECTOR_SIZE equ 0x200

; ELF specific constants
; more detailed description of ELF files:
;   - https://en.wikipedia.org/wiki/Executable_and_Linkable_Format
;   - https://wiki.osdev.org/ELF
; offset to memory address of entry point
ELF_ENTRY equ 0x18
; offset to start of program header table
ELF_PHOFF equ 0x1c
; offset to number of entries in program header table
ELF_PHNUM equ 0x2c
; size of program header
PROGRAM_HEADER_SIZE equ 0x20
; offset to program header segment size
PROGRAM_HEADER_MEMSZ equ 0x14
; offset to program header segment offset
PROGRAM_HEADER_OFFSET equ 0x04
; offset to program header segment's physical address
PROGRAM_HEADER_ADDR equ 0x0c 


; loads an ELF kernel image
; assumes that kernel image begins at second sector
; will never return if no errors occur
load_kernel:
    pusha
    
    ; read ELF header to address 0x10000
    ; assume that ELF header fits completely into 1024 bytes
    mov ebx, KERNEL_HEADER_ADDRESS
    mov ecx, 0x400
    mov edx, 0 
    call read_bytes

    ; a valid ELF header begins with 0x7f
    ; followed by ascii values in 'E', 'L', 'F'
    ; abort when it is not a valid ELF file
    cmp dword [KERNEL_HEADER_ADDRESS], 0x464c457f
    jne .finish

    ; [esi] will hold current program header, starts at:
    ; KERNEL_HEADER_ADDRESS + KERNEL_HEADER->E_PHOFF
    mov eax, [KERNEL_HEADER_ADDRESS+ELF_PHOFF]
    add eax, KERNEL_HEADER_ADDRESS
    mov esi, eax

    ; eax will hold how many program headers are left to read
    mov eax, [KERNEL_HEADER_ADDRESS+ELF_PHNUM]

; read kernel code into memory
.loop:
    
    ; load [esi+0x14] bytes starting from [esi+0x04] into
    ; physical address at [ebx+0x0c]
    mov ebx, [esi+PROGRAM_HEADER_ADDR]      ; destination address
    mov ecx, [esi+PROGRAM_HEADER_MEMSZ]     ; size of segment in memory
    mov edx, [esi+PROGRAM_HEADER_OFFSET]    ; offset of segment in file image
    call read_bytes

    ; increase pointer to program header entry by 0x20 bytes,
    ; so it points to the next program header entry
    add esi, PROGRAM_HEADER_SIZE

    ; one program header less to read
    ; if none are left to read, call kernel main function
    sub eax, 0x01
    cmp eax, 0x00
    jnz .loop

; load kernel
.call_kernel:
    call [KERNEL_HEADER_ADDRESS+ELF_ENTRY]
    

; only when could not load kernel (e.g. invalid kernel elf header)
; or when kernel returns (should never happen)
.finish:
    popa
    ret


; reads several bytes from disk
; starting at offset (beginning at second sector)
; to a physical address
; input:
;   ebx - physical destination address (start of read bytes)
;   ecx - how many bytes to read
;   edx - offset where to read from
read_bytes:
    pusha

    cmp ecx, 0x00
    jz .finish
     
    ; eax will hold physical end address of the read bytes
    ; end_address = start_address + bytes
    mov eax, ebx
    add eax, ecx

    ; round down to sector boundary
    ; start_address &= ~(sector_size - 1)
    and ebx, ~0x1ff

    ; so the sector where the data starts is:
    ; sector = (offset / 512) + 1 // kernel starts at second sector
    shr edx, 0x09   ; divide by 512
    add edx, 0x01   ; add one
    mov ecx, edx    ; read_sector expects sector to be stored in ecx
    
; read bytes sector by sector from disk
.loop:
    call read_sector
    ; 512 bytes were read to [ebx]
    ; next 512 bytes should be read to [ebx+512]
    add ebx, SECTOR_SIZE
    ; increase sector to read next
    add ecx, 0x01
    cmp ebx, eax
    jbe .loop

.finish:
    popa
    ret


; reads a single sector into physical address
; used 28 bit PIO mode to read sector
; https://wiki.osdev.org/ATA_PIO_Mode#28_bit_PIO
; this is a very simple sector reader since it
; does not check if any errors occured
; input:
;   ebx - destination (physical address)
;   ecx - sector 
read_sector:
    pusha

    call wait_disk_ready ; wait until disk is ready

    ; numbers of sectors to read (here: 1)
    mov eax, 0x01
    mov edx, 0x1f2
    out dx, al

    ; send first 8 bits of sector to read
    mov eax, ecx
    mov edx, 0x1f3
    out dx, al

    ; the next 8 bits of that sector
    shr eax, 0x08
    mov edx, 0x1f4
    out dx, al

    ; and again 8 bits of that sector
    shr eax, 0x08
    mov edx, 0x1f5
    out dx, al

    ; send last 4 bits of sector
    ; and set the 7th and 5th bit (are obsolete but required to be set to 1)

    ; and the 6th to signify that LBA addressing is used
    shr eax, 0x08
    or eax, 0xe0
    mov edx, 0x1f6
    out dx, al

    ; send the read command (0x20)
    ; https://wiki.osdev.org/ATA_Command_Matrix
    mov eax, 0x20
    mov edx, 0x1f7
    out dx, al

    call wait_disk_ready ; wait until all data is read

    ; reads the data to memory [edi]
    ; https://c9x.me/x86/html/file_module_x86_id_141.html
    mov edi, ebx
    mov ecx, 0x80
    mov edx, 0x1f0
    cld
    repnz insd

.finish:
    popa
    ret


; waits until disk is ready (read/write)
; just checks if BSY flag of status register is set
; https://wiki.osdev.org/ATA_PIO_Mode#Status_Register_.28I.2FO_base_.2B_7.29
wait_disk_ready:
    pusha
    mov edx, 0x1f7

.loop:
    in al, dx
    test al, 0x80   ; BSY flag is last bit
    jne .loop
    
.ready:
    popa
    ret
