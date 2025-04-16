#!/bin/bash
# Script para gerar um diagrama visual do microshell
# Requer: ImageMagick (para convert)

echo "Gerando diagrama do microshell..."

# Verificar se o ImageMagick está instalado
if ! command -v convert &> /dev/null; then
    echo "ImageMagick não encontrado. Por favor instale com:"
    echo "  sudo apt-get install imagemagick"
    exit 1
fi

# Criar uma imagem básica a partir do diagrama ASCII
convert -size 800x600 xc:white -font "DejaVu-Sans-Mono" \
    -pointsize 12 -fill black \
    -annotate +20+30 "$(cat diagram.txt)" \
    -bordercolor black -border 2 \
    diagram.png

echo "Diagrama gerado como diagram.png"

# Exibir tamanho
du -h diagram.png

echo "Para visualizar: xdg-open diagram.png" 