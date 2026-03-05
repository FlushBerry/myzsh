
# 🖥️ ZSH Prompt Custom - Kali Style

Un prompt ZSH personnalisé avec détection automatique VPN, environnement virtuel Python et thème coloré adapté root/user.

## 📸 Aperçu

**Utilisateur normal (bleu) :**

<img width="324" height="68" alt="image" src="https://github.com/user-attachments/assets/a1c0bb69-1ce2-4b61-8010-8bbb3eef8a17" />



**Root (rouge) :**

<img width="395" height="52" alt="image" src="https://github.com/user-attachments/assets/1a34c447-7fc0-4420-ab60-eb559d5c5023" />


## ✨ Fonctionnalités

- 🎨 **Thème root/user** — Contours rouges pour root, bleus pour utilisateur
- 🔒 **Détection VPN automatique** — OpenVPN (tun0) et WireGuard (wg0, wg1, proton0, mullvad0, customvpn)
- 🐍 **Détection venv Python** — Affiché proprement dans le prompt (sans doublon)
- 📅 **Date et heure** — Affichées en temps réel à chaque commande
- 💡 **Autosuggestions** — Suggestions basées sur l'historique (grisé)
- 🌈 **Syntax highlighting** — Coloration des commandes en temps réel
- 📦 **Installation automatique** — Script unique, backup auto, install plugins

## 🚀 Installation

```bash
git clone https://github.com/FlushBerry/myzsh.git
cd myzsh
chmod +x install_zshrc.sh
sudo ./install_zshrc.sh
```

Le script :
1. Installe `zsh-autosuggestions` et `zsh-syntax-highlighting` si absents
2. Sauvegarde le `.zshrc` existant (`.zshrc.bak.TIMESTAMP`)
3. Installe le nouveau `.zshrc` pour root
4. Propose d'installer pour les utilisateurs dans `/home/`
5. Change le shell root en zsh si nécessaire

## 📋 Prérequis

- **Kali Linux** / Debian / Ubuntu
- **zsh** installé (`apt install zsh`)
- **curl** (pour la détection IP publique VPN)

## 🔧 Interfaces VPN détectées

| Interface | Type |
|-----------|------|
| `tun0` | OpenVPN |
| `wg0`, `wg1` | WireGuard |
| `proton0` | ProtonVPN |
| `mullvad0` | Mullvad |
| `customWG` | Custom WG |

Pour ajouter une interface, modifiez la boucle `for iface in ...` dans la fonction `get_vpn_info()`.

## 🗂️ Structure

```
.
├── install_zshrc.sh    # Script d'installation
└── README.md           # Ce fichier
```

## ⚠️ Notes

- Utilisez `sudo -i` ou `su -` (pas `sudo su`) pour charger le `.zshrc` de root
- Les backups sont dans `~/.zshrc.bak.YYYYMMDDHHMMSS`
- L'IP publique est récupérée via `curl -4 ifconfig.me` (forcé IPv4)



