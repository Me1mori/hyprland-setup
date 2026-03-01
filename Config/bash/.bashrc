# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias ls='exa --icons'
alias grep='grep --color=auto'

PS1='[\u@\h \W]\$ '


# Solo en shells interactivos
[[ $- != *i* ]] && return

run_fastfetch() {
    local cols lines area

    cols=$(tput cols)
    lines=$(tput lines)
    area=$(( cols * lines ))

    if (( area >= 5000 )); then
        fastfetch
    elif (( area >= 2500 )); then
        fastfetch --config ~/.config/fastfetch/config_half.jsonc
    elif (( area >= 1200 )); then
        fastfetch --config ~/.config/fastfetch/config_corner.jsonc
    fi
}

run_fastfetch

# clear REAL (borra historial)
clear() {
    command clear
    run_fastfetch
}

# Ctrl+L (NO borra historial)
ctrl_l_fastfetch() {
    printf "\033[H\033[2J"   # limpia pantalla visible pero conserva scrollback
    run_fastfetch
}

bind -x '"\C-l": ctrl_l_fastfetch'
export PATH=$PATH:/home/me1mori/.spicetify

export PATH=$PATH:~/.spicetify
