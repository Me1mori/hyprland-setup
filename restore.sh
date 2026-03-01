#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="$(cd "$(dirname "$0")" && pwd)"

# Verificar que whiptail esté instalado
if ! command -v whiptail &>/dev/null; then
    echo "⚠️ whiptail no está instalado. Instalando..."
    sudo pacman -S --needed --noconfirm whiptail
fi

# Obtener las carpetas dentro del backup
dirs=()
choices=()
for d in "$BACKUP_DIR"/*; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    [ "$name" == "restore.sh" ] && continue
    dirs+=("$d")
    # Inicialmente todas desmarcadas
    choices+=("$name" "Restaurar $name" "OFF")
done

if [ ${#dirs[@]} -eq 0 ]; then
    echo "❌ No se encontraron carpetas para restaurar en $BACKUP_DIR"
    exit 1
fi

# Mostrar menú interactivo
SELECTIONS=$(whiptail --title "Restaurar Configuraciones" \
    --checklist "Selecciona las configuraciones a restaurar (usa espacio para marcar, enter para confirmar)" 20 80 15 \
    "${choices[@]}" 3>&1 1>&2 2>&3)

# Convertir la salida en array
SELECTIONS_ARRAY=()
for sel in $SELECTIONS; do
    # whiptail devuelve los elementos entre comillas, quitar comillas
    SELECTIONS_ARRAY+=("${sel//\"/}")
done

# Restaurar seleccionados
for sel in "${SELECTIONS_ARRAY[@]}"; do
    # Buscar el path original
    for d in "${dirs[@]}"; do
        if [[ "$(basename "$d")" == "$sel" ]]; then
            echo "📂 Restaurando $sel..."
            rsync -a --progress "$d"/ "$HOME"/
        fi
    done
done

echo "✅ Restauración completada."