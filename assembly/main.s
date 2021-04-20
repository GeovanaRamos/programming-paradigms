section .data
    file db './text.txt', 0
    len equ 1024
    base64 db 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/', 0

section .bss 
    buffer resb 3
    fd_in  resd 1
    res resb 4


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

    cmp eax, 0	        ; if eax=0, sys_read reached EOF 
	je exit			    

    ; EDX = [0,A,B,C]
    mov byte dh, [buffer]
    mov byte dl, [buffer+1]
    shl edx, 8
    mov byte dl, [buffer+2]

    ; 6 bits
    mov esi, edx
    shl edx, 14
    shr edx, 14
    shr esi, 18
    mov byte al, [base64+esi]
    mov [res], al

    ; 6 - 12 bits
    mov esi, edx
    shl edx, 20
    shr edx, 20
    shr esi, 12
    mov byte al, [base64+esi]
    mov [res+1], al

    ; 12 - 18 bits
    mov esi, edx
    shl edx, 26
    shr edx, 26
    shr esi, 6
    mov byte al, [base64+esi]
    mov [res+2], al

    ; 18 - 24 bits
    mov esi, edx
    mov byte al, [base64+esi]
    mov [res+3], al

    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, res
    mov edx, 4          ; 4 chars at a time
    int 80h      

    jmp read


exit:
    mov eax, 6          ; sys_close
    int 80h     

    mov eax, 1          ; sys_exit
    mov ebx, 0 
    int 80h