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

# ── Complétion ──
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# ── Autosuggestions ──
if [[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# ── Syntax highlighting ──
if [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# ── Couleur contours selon root ou non ──
if [[ $EUID -eq 0 ]]; then
    _BORDER_COLOR="%F{124}"
else
    _BORDER_COLOR="%F{81}"
fi

# ── VPN Info ──
get_vpn_info() {
    local tun_ip=$(ip addr show tun0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    if [[ -n "$tun_ip" ]]; then
        local pub_ip=$(curl -4 -s --max-time 2 ifconfig.me)
        echo "OpenVPN:$tun_ip:$pub_ip"
        return
    fi

    for iface in wg0 wg1 proton0 mullvad0 customvpn; do
        local wg_ip=$(ip addr show "$iface" 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
        if [[ -n "$wg_ip" ]]; then
            local pub_ip=$(curl -4 -s --max-time 2 ifconfig.me)
            echo "WireGuard:$wg_ip:$pub_ip"
            return
        fi
    done
}

# ── Precmd ──
precmd() {
    _CMD_TIME=$(date +"%d/%m/%Y|%H:%M:%S")

    local vpn_info=$(get_vpn_info)
    if [[ -n "$vpn_info" ]]; then
        local vpn_type=${vpn_info%%:*}
        local rest=${vpn_info#*:}
        local vpn_local=${rest%%:*}
        local vpn_pub=${rest##*:}
        if [[ "$vpn_type" == "WireGuard" ]]; then
            _VPN_LINE="${_BORDER_COLOR}╠═[%F{51}🔒 WireGuard: ${vpn_pub}${_BORDER_COLOR}]
"
        else
            _VPN_LINE="${_BORDER_COLOR}╠═[%F{46}🔒 VPN: ${vpn_pub}${_BORDER_COLOR}]
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
if [[ $EUID -eq 0 ]]; then
    PROMPT='%F{124}╔═[%F{196}%n%F{196}@%F{196}%m%F{124}]─[%F{119}${_CMD_TIME}%F{124}]─[%B%F{white}%~%b%F{124}]
${_VPN_LINE}${_VENV_LINE}%F{124}╚═#%f '
else
    PROMPT='%F{81}╔═[%F{39}%n%F{39}@%F{39}%m%F{81}]─[%F{119}${_CMD_TIME}%F{81}]─[%B%F{white}%~%b%F{81}]
${_VPN_LINE}${_VENV_LINE}%F{81}╚═$%f '
fi

# ── Aliases ──
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
ZSHRC_EOF

    if [[ -n "$OWNER" ]]; then
        chown "$OWNER":"$OWNER" "$TARGET"
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
    done
fi

echo ""
echo "[✔] Installation terminée."
echo "[!] Utilisez 'sudo -i' ou 'su -' pour charger le .zshrc de root."
echo "[!] Relancez votre terminal ou tapez : source ~/.zshrc"
