#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$REPO_DIR/Config"
BACKUP_DIR="$HOME/backup/$(date +%Y%m%d_%H%M%S)"

mkdir -p "$BACKUP_DIR"

echo "==============================="
echo "     Backup de Configuraciones"
echo "==============================="
echo ""

copy_with_backup() {
    local src="$1"
    local name
    name=$(basename "$src")

    if [ -d "$src" ]; then
        echo "Creando backup de $name..."
        rsync -av --ignore-missing-args "$src"/ "$BACKUP_DIR/$name/"
    else
        echo "Directorio $src no encontrado, saltando..."
    fi
}

# Copiar todo el Config
for dir in "$CONFIG_DIR"/*; do
    copy_with_backup "$dir"
done

echo ""
echo "✅ Backup completado en: $BACKUP_DIR"
echo "Puedes usar restore.sh para restaurar selectivamente los paquetes."
