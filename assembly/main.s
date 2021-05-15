section .data
    len equ 1024
    base64 db 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=', 0
    new_line db 0x0a
    invalid_msg db 'base64: invalid input', 0x0a, 0
    not_found_intro db 'base64: ', 0
    not_found db ': No such file or directory', 0x0a, 0
    help_file db '../help.txt', 0
    version_file db '../version.txt', 0

section .bss 
    buffer resb 4
    fd_in  resd 1
    res resb 4


section .text
    global _start

_start:

    pop ebx             ; argc
    mov edi, ebx
    
    pop ebx             ; remove ./main
    dec edi
    mov esi, 0          ; 0=encode 1=decode
    mov edx, 0          ; init filename

    parse_arguments:
        cmp edi, 0
        je read_input
        dec edi

        pop ebx             ; next argument
        cmp byte [ebx], '-'
        je is_double      
        mov edx, ebx        ; saves filename
        jmp parse_arguments

        is_double:
        cmp byte [ebx+1], '-'
        jne is_decode
        je is_help_double

        is_decode:
        cmp byte [ebx+1], 'd'
        jne parse_arguments
        cmp byte [ebx+2], 0
        jne parse_arguments
        mov esi, 1
        jmp parse_arguments

        is_help_double:
        cmp byte [ebx+2], 'h'
        jne is_version_double
        cmp byte [ebx+3], 'e'
        jne is_version_double
        cmp byte [ebx+4], 'l'
        jne is_version_double
        cmp byte [ebx+5], 'p'
        jne is_version_double
        cmp byte [ebx+6], 0
        jne is_version_double
        je help

        is_version_double:
        cmp byte [ebx+2], 'v'
        jne is_decode_double
        cmp byte [ebx+3], 'e'
        jne is_decode_double
        cmp byte [ebx+4], 'r'
        jne is_decode_double
        cmp byte [ebx+5], 's'
        jne is_decode_double
        cmp byte [ebx+6], 'i'
        jne is_decode_double
        cmp byte [ebx+7], 'o'
        jne is_decode_double
        cmp byte [ebx+8], 'n'
        jne is_decode_double
        cmp byte [ebx+9], 0
        jne is_decode_double
        je version

        is_decode_double:
        cmp byte [ebx+2], 'd'
        jne parse_arguments
        cmp byte [ebx+3], 'e'
        jne parse_arguments
        cmp byte [ebx+4], 'c'
        jne parse_arguments
        cmp byte [ebx+5], 'o'
        jne parse_arguments
        cmp byte [ebx+6], 'd'
        jne parse_arguments
        cmp byte [ebx+7], 'e'
        jne parse_arguments
        cmp byte [ebx+8], 0
        jne parse_arguments
        mov esi, 1
        jmp parse_arguments

    
    read_input:
    cmp edx, 0      ; check if filename is empty
    jne read_file
    mov byte [fd_in], 0
    jmp encode_or_decode
    
    read_file:
    mov ebx, edx        ; saves filename
    mov eax, 5          ; sys_open
    mov ecx, 0          ; for read only access
    int 80h   
    cmp eax, 0          ; error on sys_open
    jl file_not_found   
    mov  [fd_in], eax  

    encode_or_decode:
    cmp esi, 1          ; go to encode or decode
    je  decode_loop
    mov edi, 0          ; total res characters for encoding
    jmp encode_loop


version:
    mov ebx, version_file; saves filename
    mov eax, 5          ; sys_open
    mov ecx, 0          ; for read only access
    int 80h   

    mov  [fd_in], eax  

    jmp read_loop

help:
    mov ebx, help_file  ; saves filename
    mov eax, 5          ; sys_open
    mov ecx, 0          ; for read only access
    int 80h   

    mov  [fd_in], eax  

    jmp read_loop

read_loop:
    mov eax, 3          ; sys_read    
    mov ebx, [fd_in]
    mov ecx, buffer     
    mov edx, 3          ; 3 chars at a time    
    int 80h     

    cmp eax, 0	        ; if eax=0, sys_read reached EOF 
    je new_line_exit	
    mov esi, eax        ; copy char count

    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, buffer   
    mov edx, esi          
    int 80h   

    jmp read_loop   


file_not_found:
    mov esi, ebx

    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, not_found_intro   
    mov edx, 9          
    int 80h   

    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, esi   
    mov edx, 10          
    int 80h   

    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, not_found   
    mov edx, 28          
    int 80h   

    jmp new_line_exit


invalid_option:
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, invalid_msg   
    mov edx, 22          
    int 80h   

    jmp new_line_exit

    
encode_loop: 
    mov eax, 3          ; sys_read    
    mov ebx, [fd_in]
    mov ecx, buffer     
    mov edx, 3          ; 3 chars at a time    
    int 80h     

    cmp eax, 0	        ; if eax=0, sys_read reached EOF 
	je new_line_exit	
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
    jne encode_loop 

    ; print linebreak
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, new_line   
    mov edx, 1          
    int 80h

    jmp encode_loop


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
            cmp ebx, 66         ; invalid base64 input
            je invalid_option
            mov byte al, [buffer + esi] 
            mov byte cl, [base64 + ebx] 
            inc ebx	
            cmp al, cl          ; found index
            jne iterate_base64
            cmp ebx, 65         ; if it is '='
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
    mov edx, 3          ; 3 chars at a time
    int 80h      

    jmp decode_loop


new_line_exit:
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


exit:
    mov eax, 6          ; sys_close
    int 80h  

    mov eax, 1          ; sys_exit
    mov ebx, 0 
    int 80h
