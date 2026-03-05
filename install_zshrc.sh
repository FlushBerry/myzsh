#!/bin/bash
# install_zshrc.sh - Installation du .zshrc personnalisé

set -e

install_zshrc() {
    local TARGET="$1"
    local OWNER="$2"

    if [[ -f "$TARGET" ]]; then
        cp "$TARGET" "${TARGET}.bak.$(date +%Y%m%d%H%M%S)"
        echo "[+] Backup créé : ${TARGET}.bak.*"
    fi

    cat > "$TARGET" << 'ZSHRC_EOF'
# ══════════════════════════════════════
# ── ZSH Config ──
# ══════════════════════════════════════

setopt PROMPT_SUBST

# ── Désactiver le préfixe (venv) par défaut ──
export VIRTUAL_ENV_DISABLE_PROMPT=1

# ── Historique ──
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory sharehistory hist_ignore_dups

# ── Keybindings ──
bindkey -e

bindkey '^A'      beginning-of-line
bindkey '^E'      end-of-line
bindkey '^U'      backward-kill-line
bindkey '^K'      kill-line
bindkey '^W'      backward-kill-word
bindkey '^Y'      yank
bindkey '^R'      history-incremental-search-backward
bindkey '^S'      history-incremental-search-forward
bindkey '^L'      clear-screen
bindkey '^D'      delete-char-or-list

bindkey '^[[1;5C' forward-word               # Ctrl+Droite
bindkey '^[[1;5D' backward-word              # Ctrl+Gauche
bindkey '^[f'     forward-word               # Alt+F
bindkey '^[b'     backward-word              # Alt+B

bindkey '^[[H'    beginning-of-line          # Home
bindkey '^[[F'    end-of-line                # End
bindkey '^[[3~'   delete-char                # Suppr
bindkey '^[d'     kill-word                  # Alt+D
bindkey '^[^?'    backward-kill-word         # Alt+Backspace

# ── Complétion ──
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# ── Couleur bordure selon user ──
if [[ $EUID -eq 0 ]]; then
    _BORDER_COLOR='%F{196}'
    _USER_COLOR='%F{196}'
else
    _BORDER_COLOR='%F{81}'
    _USER_COLOR='%F{green}'
fi

# ── VPN ──
get_vpn_info() {
    # OpenVPN (tun0)
    local tun_ip=$(ip addr show tun0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    if [[ -n "$tun_ip" ]]; then
        local pub_ip=$(curl -4 -s --max-time 2 ifconfig.me)
        echo "OpenVPN:tun0:$pub_ip"
        return
    fi

    # WireGuard
    for iface in wg0 wg1 proton0 mullvad0 customvpn ; do
        local wg_ip=$(ip addr show "$iface" 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
        if [[ -n "$wg_ip" ]]; then
            local pub_ip=$(curl -4 -s --max-time 2 ifconfig.me)
            echo "WireGuard:$iface:$pub_ip"
            return
        fi
    done
}

# ── precmd : exécuté avant chaque prompt ──
precmd() {
    _CMD_TIME=$(date +"%d/%m/%Y|%H:%M:%S")

    local vpn_info=$(get_vpn_info)
    if [[ -n "$vpn_info" ]]; then
        local vpn_type=${vpn_info%%:*}
        local rest=${vpn_info#*:}
        local vpn_iface=${rest%%:*}
        local vpn_pub=${rest##*:}
        if [[ "$vpn_type" == "WireGuard" ]]; then
            _VPN_LINE="${_BORDER_COLOR}╠═[%F{51}🔒 WireGuard (${vpn_iface}): ${vpn_pub}${_BORDER_COLOR}]
"
        else
            _VPN_LINE="${_BORDER_COLOR}╠═[%F{46}🔒 VPN (${vpn_iface}): ${vpn_pub}${_BORDER_COLOR}]
"
        fi
    else
        _VPN_LINE=""
    fi

    if [[ -n "$VIRTUAL_ENV" ]]; then
        _VENV_LINE="${_BORDER_COLOR}╠═[%F{226}🐍 $(basename $VIRTUAL_ENV)${_BORDER_COLOR}]
"
    else
        _VENV_LINE=""
    fi
}

# ── Prompt ──
PROMPT='${_BORDER_COLOR}╔═[${_USER_COLOR}%n${_BORDER_COLOR}@${_USER_COLOR}%m${_BORDER_COLOR}]─[%F{white}${_CMD_TIME}${_BORDER_COLOR}]─[%B%F{white}%~%b${_BORDER_COLOR}]
${_VPN_LINE}${_VENV_LINE}${_BORDER_COLOR}╚═#%f '

# ── Plugins ──
[[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

ZSHRC_EOF

    if [[ -n "$OWNER" ]]; then
        chown "$OWNER:$OWNER" "$TARGET"
    fi

    echo "[+] .zshrc installé dans $TARGET"
}

# ── Vérification root ──
if [[ $EUID -ne 0 ]]; then
    echo "[!] Lancez avec : sudo ./install_zshrc.sh"
    exit 1
fi

# ── Installer les plugins si absents ──
if ! dpkg -l zsh-autosuggestions &>/dev/null; then
    echo "[+] Installation de zsh-autosuggestions..."
    apt install -y zsh-autosuggestions
fi
if ! dpkg -l zsh-syntax-highlighting &>/dev/null; then
    echo "[+] Installation de zsh-syntax-highlighting..."
    apt install -y zsh-syntax-highlighting
fi

# ── Installation root ──
install_zshrc "/root/.zshrc" ""

current_shell=$(getent passwd root | cut -d: -f7)
if [[ "$current_shell" != *"zsh"* ]]; then
    chsh -s $(which zsh) root 2>/dev/null && echo "[+] Shell root changé en zsh"
fi

# ── Installation users ──
read -p "[?] Installer aussi pour les utilisateurs dans /home/ ? (y/N) " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    for user_home in /home/*/; do
        user=$(basename "$user_home")
        install_zshrc "${user_home}.zshrc" "$user"
        user_shell=$(getent passwd "$user" | cut -d: -f7)
        if [[ "$user_shell" != *"zsh"* ]]; then
            chsh -s $(which zsh) "$user" 2>/dev/null && echo "[+] Shell de $user changé en zsh"
        fi
    done
fi

echo ""
echo "[✔] Installation terminée."
echo "[!] Relancez votre terminal ou tapez : source ~/.zshrc"
