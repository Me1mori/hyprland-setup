#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$REPO_DIR/Config"

echo "==============================="
echo "   Hyprland Setup Installer"
echo "==============================="
echo ""

# 0️⃣ Preguntar por backup
read -rp "¿Deseas hacer un backup de tus configuraciones actuales antes de instalar? (s/n): " BACKUP_CONFIRM
if [[ "$BACKUP_CONFIRM" =~ ^[Ss]$ ]]; then
    BACKUP_DIR="$HOME/backup/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    echo ""
    echo "📦 Creando backup en: $BACKUP_DIR ..."

    copy_with_backup() {
        local src="$1"
        local name
        name=$(basename "$src")
        if [ -d "$src" ]; then
            echo "Backup de $name..."
            rsync -a --ignore-missing-args "$src"/ "$BACKUP_DIR/$name/"
        else
            echo "⚠️ $src no encontrado, saltando..."
        fi
    }

    # Hacer backup de todo Config/
    for dir in "$CONFIG_DIR"/*; do
        copy_with_backup "$dir"
    done

    # Crear restore.sh dentro del backup
    cat > "$BACKUP_DIR/restore.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
BACKUP_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "==============================="
echo "  Restaurar Configuraciones"
echo "==============================="
dirs=()
i=1
for d in "$BACKUP_DIR"/*; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    [ "$name" == "restore.sh" ] && continue
    dirs+=("$d")
    echo "$i) $name"
    ((i++))
done

echo ""
echo "Ingresa los números de las carpetas a restaurar separados por espacios (ej: 1 3 5):"
read -rp "> " SELECTIONS
for sel in $SELECTIONS; do
    idx=$((sel-1))
    if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#dirs[@]}" ]; then
        src="${dirs[$idx]}"
        dst="$HOME"
        echo "Restaurando $(basename "$src")..."
        rsync -a --progress "$src"/ "$dst"/
    fi
done
echo "✅ Restauración completada."
EOF
    chmod +x "$BACKUP_DIR/restore.sh"
    echo "✅ Backup completado y restore.sh creado en $BACKUP_DIR"
fi

# 1️⃣ Solicitar tipo de instalación de paquetes
echo ""
echo "¿Qué paquetes deseas instalar?"
echo "1) Solo pacman"
echo "2) Solo AUR"
echo "3) Ambos"
read -rp "Opción (1/2/3): " INSTALL_TYPE

install_packages() {
    local pkg_file="$1"
    local type="$2"
    if [ ! -f "$pkg_file" ]; then
        echo "⚠️ $pkg_file no encontrado. Saltando $type..."
        return
    fi

    echo ""
    echo "📦 Instalando paquetes $type desde $pkg_file..."
    packages=$(grep -v '^#' "$pkg_file" | grep -v '^$')
    to_install=()
    for pkg in $packages; do
        if [[ "$type" == "pacman" ]]; then
            if ! pacman -Qi "$pkg" &>/dev/null; then
                to_install+=("$pkg")
            fi
        else
            if ! pacman -Qi "$pkg" &>/dev/null && ! yay -Qi "$pkg" &>/dev/null; then
                to_install+=("$pkg")
            fi
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        echo "Instalando: ${to_install[*]}"
        if [[ "$type" == "pacman" ]]; then
            sudo pacman -Syu --needed --noconfirm "${to_install[@]}"
        else
            if ! command -v yay &>/dev/null; then
                echo "🔧 Instalando yay..."
                sudo pacman -S --needed --noconfirm base-devel git
                git clone https://aur.archlinux.org/yay.git /tmp/yay
                (cd /tmp/yay && makepkg -si --noconfirm)
                rm -rf /tmp/yay
            fi
            yay -S --needed --noconfirm "${to_install[@]}"
        fi
    else
        echo "✅ Todos los paquetes $type ya están instalados."
    fi
}

# 2️⃣ Actualizar sistema y ejecutar instalación de paquetes
echo ""
echo "🔄 Actualizando sistema..."
sudo pacman -Syu --noconfirm

case $INSTALL_TYPE in
    1) install_packages "$REPO_DIR/packages.txt" "pacman" ;;
    2) install_packages "$REPO_DIR/aur.txt" "aur" ;;
    3)
        install_packages "$REPO_DIR/packages.txt" "pacman"
        install_packages "$REPO_DIR/aur.txt" "aur"
        ;;
    *) echo "Opción inválida, se instalarán ambos por defecto."
       install_packages "$REPO_DIR/packages.txt" "pacman"
       install_packages "$REPO_DIR/aur.txt" "aur"
       ;;
esac

# 3️⃣ Habilitar servicios esenciales
echo ""
echo "🔧 Habilitando servicios esenciales..."
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth

# 4️⃣ Copiar configuraciones
copy_config() {
    local src="$1"
    local dst="$HOME"
    if [ -d "$src" ]; then
        echo "📂 Copiando configuración desde $(basename "$src")..."
        rsync -a --progress "$src"/ "$dst"/
    else
        echo "⚠️ Directorio $src no encontrado, saltando."
    fi
}

copy_config "$CONFIG_DIR/bash"
copy_config "$CONFIG_DIR/mimeapps.list"
copy_config "$CONFIG_DIR/hypr"
copy_config "$CONFIG_DIR/waybar"
copy_config "$CONFIG_DIR/rofi"
copy_config "$CONFIG_DIR/rofi-power-menu"
copy_config "$CONFIG_DIR/waypaper"
copy_config "$CONFIG_DIR/kitty"
copy_config "$CONFIG_DIR/fastfetch"

# 5️⃣ Instalar drivers GPU
echo ""
echo "🖥 Selecciona tu GPU:"
echo "1) Intel"
echo "2) AMD / Ryzen"
echo "3) NVIDIA"
echo "4) Máquina Virtual"
echo "5) Ninguna / Default Mesa"
read -rp "Opción: " GPU_OPTION

install_gpu_drivers() {
    case $1 in
        1) sudo pacman -S --needed --noconfirm mesa vulkan-intel intel-media-driver ;;
        2) sudo pacman -S --needed --noconfirm mesa vulkan-radeon xf86-video-amdgpu ;;
        3)
            sudo pacman -S --needed --noconfirm nvidia nvidia-utils nvidia-settings
            echo "⚠️ NVIDIA en Wayland puede requerir configuración adicional."
            ;;
        4) sudo pacman -S --needed --noconfirm mesa xf86-video-vmware virtualbox-guest-utils ;;
        5|*) sudo pacman -S --needed --noconfirm mesa ;;
    esac
}

install_gpu_drivers "$GPU_OPTION"

# 6️⃣ Instalar y habilitar Hyprlock con systemd --user
echo ""
if ! command -v hyprlock &>/dev/null; then
    echo "🔒 Instalando Hyprlock..."
    sudo pacman -S --needed --noconfirm hyprland
fi

USER_SYSTEMD_DIR="$HOME/.config/systemd/user"
mkdir -p "$USER_SYSTEMD_DIR"

cat > "$USER_SYSTEMD_DIR/hyprlock.service" <<'EOF'
[Unit]
Description=Hyprland Lock Screen
After=graphical.target

[Service]
ExecStart=/usr/bin/env hyprlock
Restart=always
Type=simple

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable hyprlock.service
systemctl --user start hyprlock.service

echo ""
echo "✅ Instalación y configuración completadas."

if [[ "$BACKUP_CONFIRM" =~ ^[Ss]$ ]]; then
    echo "📂 Backup disponible en $BACKUP_DIR"
    echo "Puedes restaurar selectivamente con:"
    echo "   $BACKUP_DIR/restore.sh"
fi

echo ""
echo "Para iniciar Hyprland:"
echo "   export XDG_SESSION_TYPE=wayland"
echo "   export XDG_CURRENT_DESKTOP=Hyprland"
echo "   exec Hyprland"
echo "Hyprlock ahora se iniciará automáticamente al iniciar Hyprland."