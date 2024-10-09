#! /bin/bash

echo "[*] Starting Script.."
distro=""

get_distro() {
    if grep -q '^ID_LIKE=' /etc/os-release; then
        distro=$(grep '^ID_LIKE=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    else
        distro=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    fi
}


update_db() {
    echo "[*] Updating Package Database.."

    if [[ $distro == "arch" ]]; then
        echo "[*] Running `sudo pacman -Sy`"
        sudo pacman -Sy || { echo "[*] Failed to Update"; exit 1; }
    elif [[ $distro == "ubuntu" || $distro == "debian" ]]; then
        echo "[*] Running `sudo apt update`"
        sudo apt update || { echo "[*] Failed to Update"; exit 1; }
    else
        echo "[*] Unsupported distribution"
        exit 1
    fi

    echo "[*] Successfully Updated."
}


install_k3s() {
    echo "[*] Installing k3s.."

    if [[ $distro == "arch" ]]; then
        echo "[*] Running `yay -S --noconfirm k3s-bin`.."
        yay -S --noconfirm k3s-bin || { echo "[*] Failed to install k3s"; exit 1; }
    elif [[ $distro == "ubuntu" || $distro == "debian" ]]; then
        echo "[*] Running `curl -sfL https://get.k3s.io | sh -`.."
        curl -sfL https://get.k3s.io | sh - || { echo "[*] Failed to install k3s"; exit 1; }
    else
        echo "[*] Unsupported distribution"
        exit 1
    fi

    echo "[*] Successfully Installed k3s"
    echo "[*] Enabling k3s.."
    sudo systemctl enable --now k3s
}


install_kubernetes() {
    echo "[*] Installing Kubernetes and Kubectl.."

    if [[ $distro == "arch" ]]; then
        echo "[*] Running `sudo pacman -S kubeadm kubectl kubelet`.."
        sudo pacman -S kubeadm kubectl kubelet || { echo "[*] Failed to install Kubernetes"; exit 1; }
    elif [[ $distro == "ubuntu" || $distro == "debian" ]]; then
        echo "[*] Installing prerequisites.."
        sudo apt-get install -y apt-transport-https ca-certificates curl || { echo "[*] Failed to install prerequisites"; exit 1; }
        
        echo "[*] Adding Kubernetes GPG key.."
        curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - || { echo "[*] Failed to add GPG key"; exit 1; }
        
        echo "[*] Adding Kubernetes repository.."
        echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list || { echo "[*] Failed to add repository"; exit 1; }
        
        sudo apt-get update || { echo "[*] Failed to update package lists"; exit 1; }
        
        echo "[*] Running `sudo apt-get install -y kubelet kubeadm kubectl`"
        sudo apt-get install -y kubelet kubeadm kubectl || { echo "[*] Failed to install Kubernetes components"; exit 1; }
    else
        echo "[*] Unsupported distribution"
        exit 1
    fi

    echo "[*] Successfully Installed Kubernetes components."
    echo "[*] Enabling Kubelet.."
    sudo systemctl enable --now kubelet
}


get_distro
update_db
install_k3s
install_kubernetes

