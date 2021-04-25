section .data
    file db './text2.txt', 0
    len equ 1024
    base64 db 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=', 0
    new_line db 0x0a
    not_found db 'Arquivo não encontrado', 0x0a, 0

section .bss 
    buffer resb 4
    fd_in  resd 1
    res resb 4


section .text
    global _start

_start:

    pop ebx             ; argc
    cmp ebx, 2          ; check if there are at least two
    jl exit
    
    pop ebx             ; remove ./main
    pop ebx             ; next argument

    ;mov ebx, ebx       ; saves filename
    mov eax, 5          ; sys_open
    mov ecx, 0          ; for read only access
    int 80h   

    cmp eax, 0          ; error on sys_open
    jl file_not_found   

    mov  [fd_in], eax   

    jmp decode_loop

    mov edi, 0          ; total res characters for encoding

read: 
    mov eax, 3          ; sys_read    
    mov ebx, [fd_in]
    mov ecx, buffer     
    mov edx, 3          ; 3 chars at a time    
    int 80h     

    cmp eax, 0	        ; if eax=0, sys_read reached EOF 
	je exit	
    mov ebx, eax        ; copy char count
		    
    ; EDX = [0,A,B,C]
    mov byte dh, [buffer]
    mov byte dl, [buffer+1]
    shl edx, 8
    mov byte dl, [buffer+2]

    ; pad zeros
    cmp ebx, 3
    je encode
    mov byte dl, 0      ; padded one 0
    cmp ebx, 2
    je encode
    mov byte dh, 0      ; padded two 0s        

    encode:
    shl edx, 8          ; EDX = [A,B,C,0] 
    mov ecx, 0          ; counter

    fill_res:
        mov esi, edx
        shr esi, 26         ; get first 6 bits
        mov byte al, [base64+esi]
        mov byte [res+ecx], al
        shl edx, 6          ; clear first 6 bits
        inc ecx
        cmp ecx, 4
        jne fill_res

    ; pad =
    cmp ebx, 3
    je print_encode
    mov byte [res+3], '='      ; padded one =
    cmp ebx, 2
    je print_encode
    mov byte [res+2], '='      ; padded two =

    print_encode:
    ; print
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, res
    mov edx, 4          ; 4 chars at a time
    int 80h      

    ; update character count
    add edi, 4          

    ; check line chars 
    mov eax, edi
    mov bl, 76
    div bl
    cmp ah, 0           ; if line has 76 chars       
    jne read 

    ; print linebreak
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, new_line   
    mov edx, 1          
    int 80h

    jmp read


decode_loop:
    
    mov eax, 3          ; sys_read    
    mov ebx, [fd_in]
    mov ecx, buffer     
    mov edx, 4          ; 4 chars at a time    
    int 80h     

    cmp eax, 0	        ; if eax=0, sys_read reached EOF 
	je exit	
    cmp eax, 4			; invalid base64 input
	jl exit				

    xor esi, esi
    xor edx, edx

    ; replace base64 char by its index
    find_index:
        xor ebx, ebx
        iterate_base64:
            cmp ebx, 65         ; invalid base64 input
            je exit
            mov byte al, [buffer + esi] 
            mov byte cl, [base64 + ebx] 
            inc ebx	
            cmp al, cl          ; found index
            jne iterate_base64
            cmp ebx, 64         ; if it is '='
            jne save_index
            mov ebx, 1          ; ebx will be 0
        save_index:    
        dec ebx
        shl edx, 6          ; clears space for next index
        or dl, bl           ; add index to edx
        inc esi
        cmp esi, 4
        jne find_index
    
    
    mov byte [res+2], dl 
    shr edx, 8
    mov byte [res+1], dl
    shr edx, 8
    mov byte [res], dl

    ; print
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, res
    mov edx, 5          ; 3 chars at a time
    int 80h      

    jmp decode_loop


file_not_found:
    mov esi, ebx

    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, not_found   
    mov edx, 24          
    int 80h   

exit:
    mov eax, 6          ; sys_close
    int 80h  

    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, new_line   
    mov edx, 1          
    int 80h   

    mov eax, 1          ; sys_exit
    mov ebx, 0 
    int 80h