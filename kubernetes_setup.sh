#!/bin/bash

LOG_FILE="script_output.log"

log() {
    echo "$1" | tee -a "$LOG_FILE"
}

log "[*] Starting Script.."

get_distro() {
    if grep -q '^ID_LIKE=' /etc/os-release; then
        distro=$(grep '^ID_LIKE=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    else
        distro=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    fi
}

update_db() {
    log "[*] Updating Package Database.."

    if [[ $distro == "arch" ]]; then
        echo "[*] Running sudo pacman -Sy"
        sudo pacman -Sy || { echo "[*] Failed to update package database"; exit 1; }
    elif [[ $distro == "ubuntu" || $distro == "debian" ]]; then
        echo "[*] Running sudo apt update"
        sudo apt update || { echo "[*] Failed to update package database"; exit 1; }
    else
        echo "[*] Unsupported distribution for updating database"
        exit 1
    fi

    log "[*] Successfully Updated."
}

install_k3s() {
    log "[*] Installing k3s.."

    if [[ $distro == "arch" ]]; then
        echo "[*] Running yay -S --noconfirm k3s-bin"
        yay -S --noconfirm k3s-bin || { echo "[*] Failed to install k3s"; exit 1; }
    elif [[ $distro == "ubuntu" || $distro == "debian" ]]; then
        echo "[*] Running curl -sfL https://get.k3s.io | sh -"
        curl -sfL https://get.k3s.io | sh - || { echo "[*] Failed to install k3s"; exit 1; }
    else
        echo "[*] Unsupported distribution for k3s installation"
        exit 1
    fi

    log "[*] Successfully Installed k3s"
    sudo systemctl enable --now k3s
}

install_kubectl() {
    log "[*] Installing kubectl.."

    if [[ $distro == "ubuntu" || $distro == "debian" ]]; then
        echo "[*] Running curl -LO \"https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\""
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" || { echo "[*] Failed to download kubectl"; exit 1; }
        
        echo "[*] Running sudo mv kubectl /usr/local/bin/"
        sudo mv kubectl /usr/local/bin/ || { echo "[*] Failed to move kubectl"; exit 1; }

        echo "[*] Running sudo chmod +x /usr/local/bin/kubectl"
        sudo chmod +x /usr/local/bin/kubectl || { echo "[*] Failed to make kubectl executable"; exit 1; }

        log "[*] Successfully Installed kubectl."
    else
        echo "[*] Unsupported distribution for kubectl installation"
        exit 1
    fi
}

get_distro
update_db
install_k3s
install_kubectl
