#!/bin/bash
set -e

CONFIG_DIR="home"

echo "==============================="
echo "   Hyprland Setup Installer"
echo "==============================="
echo ""

echo "Actualizando sistema..."
sudo pacman -Syu --noconfirm

echo ""
echo "Instalando paquetes base..."
sudo pacman -S --needed --noconfirm $(grep -v '^#' packages.txt | grep -v '^$')

echo ""
echo "Selecciona tu GPU:"
echo "1) Intel"
echo "2) AMD / Ryzen"
echo "3) NVIDIA"
echo "4) Máquina Virtual"
echo "5) Ninguna / Default Mesa"
echo ""

read -p "Opción: " GPU_OPTION

case $GPU_OPTION in
    1)
        echo "Instalando drivers Intel..."
        sudo pacman -S --needed --noconfirm mesa vulkan-intel intel-media-driver
        ;;
    2)
        echo "Instalando drivers AMD..."
        sudo pacman -S --needed --noconfirm mesa vulkan-radeon xf86-video-amdgpu
        ;;
    3)
        echo "Instalando drivers NVIDIA..."
        sudo pacman -S --needed --noconfirm nvidia nvidia-utils nvidia-settings
        echo "IMPORTANTE: NVIDIA en Wayland puede requerir configuración adicional."
        ;;
    4)
        echo "Instalando drivers para Máquina Virtual..."
        sudo pacman -S --needed --noconfirm mesa xf86-video-vmware virtualbox-guest-utils
        ;;
    5)
        echo "Usando Mesa genérico."
        sudo pacman -S --needed --noconfirm mesa
        ;;
    *)
        echo "Opción inválida. Continuando con Mesa genérico."
        sudo pacman -S --needed --noconfirm mesa
        ;;
esac

# --- AUR ---
if [ -f aur.txt ]; then
    echo ""
    echo "Instalando soporte AUR..."

    if ! command -v yay &> /dev/null; then
        sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ..
        rm -rf yay
    fi

    yay -S --needed --noconfirm $(grep -v '^#' aur.txt | grep -v '^$')
fi

# --- Servicios esenciales ---
echo ""
echo "Habilitando servicios..."
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth

# --- Crear carpetas usuario ---
xdg-user-dirs-update

# --- Copiar configuraciones ---
if [ -d "$CONFIG_DIR" ]; then
    echo ""
    echo "Copiando configuraciones..."
    rsync -av --progress "$CONFIG_DIR"/ ~/
else
    echo "Directorio de config no encontrado."
fi

echo ""
echo "Instalación completada ✔"

read -p "¿Iniciar Hyprland ahora? (s/n): " START_NOW

if [[ "$START_NOW" == "s" || "$START_NOW" == "S" ]]; then
    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=Hyprland
    exec Hyprland
else
    echo "Puedes iniciarlo manualmente con: Hyprland"
fi