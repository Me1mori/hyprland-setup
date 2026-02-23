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

# Extraemos los paquetes reales de packages.txt
PACKAGES=$(grep -v '^#' packages.txt | grep -v '^$')

# Verificamos qué paquetes NO están instalados
PKGS_TO_INSTALL=()
for pkg in $PACKAGES; do
    if ! pacman -Qi "$pkg" &> /dev/null; then
        PKGS_TO_INSTALL+=("$pkg")
    fi
done

if [ ${#PKGS_TO_INSTALL[@]} -eq 0 ]; then
    echo "Todos los paquetes base ya están instalados."
    PACKAGES_INSTALLED=true
else
    sudo pacman -S --needed --noconfirm "${PKGS_TO_INSTALL[@]}"
    PACKAGES_INSTALLED=false
fi

echo ""
echo "Selecciona tu GPU:"
echo "1) Intel"
echo "2) AMD / Ryzen"
echo "3) NVIDIA"
echo "4) Máquina Virtual"
echo "5) Ninguna / Default Mesa"
echo ""

read -rp "Opción: " GPU_OPTION

install_gpu_drivers() {
    case $1 in
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
}

install_gpu_drivers "$GPU_OPTION"

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

    # Similar chequeo para paquetes AUR (opcional)
    AUR_PACKAGES=$(grep -v '^#' aur.txt | grep -v '^$')
    AUR_TO_INSTALL=()
    for pkg in $AUR_PACKAGES; do
        if ! pacman -Qi "$pkg" &> /dev/null && ! yay -Qi "$pkg" &> /dev/null; then
            AUR_TO_INSTALL+=("$pkg")
        fi
    done

    if [ ${#AUR_TO_INSTALL[@]} -eq 0 ]; then
        echo "Todos los paquetes AUR ya están instalados."
        AUR_INSTALLED=true
    else
        yay -S --needed --noconfirm "${AUR_TO_INSTALL[@]}"
        AUR_INSTALLED=false
    fi
else
    AUR_INSTALLED=true
fi

# --- Servicios esenciales ---
echo ""
echo "Habilitando servicios..."
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth

# --- Crear carpetas usuario ---
xdg-user-dirs-update
sudo pacman -S rsync --noconfirm

# --- Copiar configuraciones ---
if [ -d "$CONFIG_DIR" ]; then
    echo ""
    echo "Copiando configuraciones..."
    rsync -av --progress "$CONFIG_DIR"/ ~/
else
    echo "Directorio de config no encontrado."
fi

echo ""
# Pregunta para reiniciar o iniciar solo si algo se instaló o actualizó
if [ "$PACKAGES_INSTALLED" = false ] || [ "$AUR_INSTALLED" = false ]; then
    read -rp "¿Quieres iniciar Hyprland ahora? (s/n): " START

    if [[ "$START" =~ ^[Ss]$ ]]; then
        export XDG_SESSION_TYPE=wayland
        export XDG_CURRENT_DESKTOP=Hyprland
        exec Hyprland
    else
        read -rp "¿Quieres reiniciar el sistema ahora? (s/n): " REBOOT

        if [[ "$REBOOT" =~ ^[Ss]$ ]]; then
            echo "Reiniciando..."
            sudo reboot
        else
            echo "Recuerda reiniciar o iniciar Hyprland manualmente."
        fi
    fi
else
    echo "No hubo cambios en paquetes, no es necesario reiniciar."
    echo "Puedes iniciar Hyprland manualmente con: Hyprland"
fi