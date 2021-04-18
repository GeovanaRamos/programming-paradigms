section .data
    file db './text.txt', 0
    len equ 1024

section .bss 
    buffer resb 3
    fd_in  resb 1


section .text
    global _start

_start:

    mov ebx, file       ; saves filename
    mov eax, 5          ; sys_open
    mov ecx, 0          ; for read only access
    int 80h      

    mov  [fd_in], eax

read: 
    mov eax, 3          ; sys_read    
    mov ebx, [fd_in]
    mov ecx, buffer     
    mov edx, 3          ; 3 chars at a time    
    int 80h     

    cmp eax, 0	        ; If eax=0, sys_read reached EOF on stdin NUMERO DE CHARS LIDOS
	je exit			    ; Jump If Equal (to 0, from compare)

    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, buffer
    mov edx, 3          ; 3 chars at a time
    int 80h      

    jmp read


exit:
    mov eax, 6          ; sys_close
    int 80h     

    mov eax, 1          ; sys_exit
    mov ebx, 0 
    int 80h