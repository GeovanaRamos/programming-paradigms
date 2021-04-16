section .data
    file db "./text.txt", 0
    len equ 1024

section .bss 
    buffer: resb 1024


section .text
    global _start

_start:

    mov ebx, file       ; saves filename
    mov eax, 5          ; sys_open
    mov ecx, 0          ; for read only access
    int 80h       

    mov eax, 3          ; sys_read
    mov ebx, eax        
    mov ecx, buffer     
    mov edx, len    
    int 80h     

    mov eax, 4          ; sys_write
    mov ebx, 1          
    mov ecx, buffer 
    mov edx, len    
    int 80h     

    mov eax, 6          ; sys_close
    int 80h     

    mov eax, 1          ; sys_exit
    mov ebx, 0 
    int 80h