#!/bin/bash

# Busca la interfaz de red por la que sale el tráfico a internet (la ruta default)
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

if [ -n "$INTERFACE" ]; then
    # Si la interfaz empieza por 'w', es Wi-Fi, intentamos sacar el SSID
    if [[ $INTERFACE == w* ]]; then
        SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
        echo "  ${SSID:-Conectado}"
    else
        # Si no es Wi-Fi, es cable o bridge
        echo "   Ethernet"
    fi
else
    echo "   Desconectado"
fi
