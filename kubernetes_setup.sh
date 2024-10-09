#! /bin/bash

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
        log "[*] Running `sudo pacman -Sy`"
        sudo pacman -Sy 2>&1 | tee -a "$LOG_FILE" || { log "[*] Failed to Update"; exit 1; }
    elif [[ $distro == "ubuntu" || $distro == "debian" ]]; then
        log "[*] Running `sudo apt update`"
        sudo apt update 2>&1 | tee -a "$LOG_FILE" || { log "[*] Failed to Update"; exit 1; }
    else
        log "[*] Unsupported distribution for updating database"
        exit 1
    fi

    log "[*] Successfully Updated."
}

install_k3s() {
    log "[*] Installing k3s.."

    if [[ $distro == "arch" ]]; then
        log "[*] Running `yay -S --noconfirm k3s-bin`.."
        yay -S --noconfirm k3s-bin 2>&1 | tee -a "$LOG_FILE" || { log "[*] Failed to install k3s"; exit 1; }
    elif [[ $distro == "ubuntu" || $distro == "debian" ]]; then
        log "[*] Running `curl -sfL https://get.k3s.io | sh -`.."
        curl -sfL https://get.k3s.io | sh - 2>&1 | tee -a "$LOG_FILE" || { log "[*] Failed to install k3s"; exit 1; }
    else
        log "[*] Unsupported distribution for k3s installation"
        exit 1
    fi

    log "[*] Successfully Installed k3s"
    log "[*] Enabling k3s.."
    sudo systemctl enable --now k3s 2>&1 | tee -a "$LOG_FILE"
}

install_kubernetes() {
    log "[*] Installing Kubernetes components (kubeadm, kubelet, kubectl).."

    if [[ $distro == "arch" ]]; then
        log "[*] Running `sudo pacman -S kubeadm kubectl kubelet`.."
        sudo pacman -S kubeadm kubectl kubelet 2>&1 | tee -a "$LOG_FILE" || { log "[*] Failed to install Kubernetes"; exit 1; }
    elif [[ $distro == "ubuntu" || $distro == "debian" ]]; then
        
        KUBE_VERSION="v1.26.0" 
        log "[*] Downloading Kubernetes binaries for version $KUBE_VERSION.."

        for component in kubelet kubeadm kubectl; do
            log "[*] Downloading $component.."
            curl -LO "https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/${component}-linux-amd64"
            sudo mv "${component}-linux-amd64" "/usr/local/bin/${component}"
            sudo chmod +x "/usr/local/bin/${component}"
        done

        
        log "[*] Enabling Kubelet.."
        sudo systemctl enable --now kubelet 2>&1 | tee -a "$LOG_FILE" || { log "[*] Failed to enable Kubelet"; exit 1; }
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
