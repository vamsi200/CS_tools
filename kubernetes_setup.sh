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
        sudo pacman -Sy > /dev/null 2>&1 || { log "[*] Failed to Update"; exit 1; }
    elif [[ $distro == "ubuntu" || $distro == "debian" ]]; then
        sudo apt update > /dev/null 2>&1 || { log "[*] Failed to Update"; exit 1; }
    else
        log "[*] Unsupported distribution for updating database"
        exit 1
    fi

    log "[*] Successfully Updated."
}

install_k3s() {
    log "[*] Installing k3s.."

    if [[ $distro == "arch" ]]; then
        yay -S --noconfirm k3s-bin > /dev/null 2>&1 || { log "[*] Failed to install k3s"; exit 1; }
    elif [[ $distro == "ubuntu" || $distro == "debian" ]]; then
        curl -sfL https://get.k3s.io | sh - > /dev/null 2>&1 || { log "[*] Failed to install k3s"; exit 1; }
    else
        log "[*] Unsupported distribution for k3s installation"
        exit 1
    fi

    log "[*] Successfully Installed k3s"
    sudo systemctl enable --now k3s > /dev/null 2>&1
}

install_kubectl() {
    log "[*] Installing kubectl.."

    if [[ $distro == "ubuntu" || $distro == "debian" ]]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" > /dev/null 2>&1 \
        && sudo mv kubectl /usr/local/bin/ > /dev/null 2>&1 \
        && sudo chmod +x /usr/local/bin/kubectl > /dev/null 2>&1 || { log "[*] Failed to download or install kubectl"; exit 1; }

        log "[*] Successfully Installed kubectl."
    else
        log "[*] Unsupported distribution for kubectl installation"
        exit 1
    fi
}

get_distro
update_db
install_k3s
install_kubectl
