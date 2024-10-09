#! /bin/bash

LOG_FILE="output.log"

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
    log "[*] Installing Kubernetes and Kubectl.."

    if [[ $distro == "arch" ]]; then
        log "[*] Running `sudo pacman -S kubeadm kubectl kubelet`.."
        sudo pacman -S kubeadm kubectl kubelet 2>&1 | tee -a "$LOG_FILE" || { log "[*] Failed to install Kubernetes"; exit 1; }
    elif [[ $distro == "ubuntu" || $distro == "debian" ]]; then
        log "[*] Installing prerequisites.."
        sudo apt-get install -y apt-transport-https ca-certificates curl 2>&1 | tee -a "$LOG_FILE" || { log "[*] Failed to install prerequisites"; exit 1; }
        
        log "[*] Adding Kubernetes GPG key.."
        curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - 2>&1 | tee -a "$LOG_FILE" || { log "[*] Failed to add GPG key"; exit 1; }
        
        log "[*] Adding Kubernetes repository.."
        echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list 2>&1 | tee -a "$LOG_FILE" || { log "[*] Failed to add repository"; exit 1; }
        
        sudo apt-get update 2>&1 | tee -a "$LOG_FILE" || { log "[*] Failed to update package lists"; exit 1; }
        
        log "[*] Running `sudo apt-get install -y kubelet kubeadm kubectl`"
        sudo apt-get install -y kubelet kubeadm kubectl 2>&1 | tee -a "$LOG_FILE" || { log "[*] Failed to install Kubernetes components"; exit 1; }
    else
        log "[*] Unsupported distribution for Kubernetes installation"
        exit 1
    fi

    log "[*] Successfully Installed Kubernetes components."
    log "[*] Enabling Kubelet.."
    sudo systemctl enable --now kubelet 2>&1 | tee -a "$LOG_FILE"
}

get_distro
update_db
install_k3s
install_kubernetes
