all: microshell

microshell: microshell.asm
	nasm -f elf64 microshell.asm -o microshell.o
	ld microshell.o -o microshell
	@echo "Tamanho do binário: $$(du -h microshell | cut -f1)"

debug: microshell.asm
	nasm -f elf64 -g -F dwarf microshell.asm -o microshell_debug.o
	ld microshell_debug.o -o microshell_debug

test: microshell
	@echo "Executando microshell com valores padrão (127.0.0.1:4444)"
	@echo "Certifique-se de ter um netcat ouvindo na porta 4444"

clean:
	rm -f microshell.o microshell microshell_debug.o microshell_debug

size_compare: microshell
	@echo "== Comparativo de tamanho de shells reversos =="
	@echo "microshell (Assembly): $$(du -h microshell | cut -f1)"
	@if [ -f c_shell ]; then echo "C shell: $$(du -h c_shell | cut -f1)"; fi
	@if [ -f python_shell.py ]; then echo "Python script: $$(du -h python_shell.py | cut -f1)"; fi
	@if [ -f go_shell ]; then echo "Go shell: $$(du -h go_shell | cut -f1)"; fi
	@if [ -f rust_shell ]; then echo "Rust shell: $$(du -h rust_shell | cut -f1)"; fi

.PHONY: all clean test debug size_compare