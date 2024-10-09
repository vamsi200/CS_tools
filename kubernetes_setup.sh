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

install_kubernetes() {
    log "[*] Installing Kubernetes components (kubeadm, kubelet, kubectl).."

    if [[ $distro == "arch" ]]; then
        sudo pacman -S kubeadm kubectl kubelet > /dev/null 2>&1 || { log "[*] Failed to install Kubernetes"; exit 1; }
    elif [[ $distro == "ubuntu" || $distro == "debian" ]]; then
        KUBE_VERSION="v1.26.0"

        for component in kubelet kubeadm kubectl; do
            curl -LO "https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/${component}-linux-amd64" > /dev/null 2>&1 \
            && sudo mv "${component}-linux-amd64" "/usr/local/bin/${component}" > /dev/null 2>&1 \
            && sudo chmod +x "/usr/local/bin/${component}" > /dev/null 2>&1 || { log "[*] Failed to download or install $component"; exit 1; }
        done

        sudo systemctl enable --now kubelet > /dev/null 2>&1 || { log "[*] Failed to enable Kubelet"; exit 1; }
    else
        log "[*] Unsupported distribution for Kubernetes installation"
        exit 1
    fi

    log "[*] Successfully Installed Kubernetes components."
}

get_distro
update_db
install_k3s
install_kubernetes
