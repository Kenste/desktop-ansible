#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Detect distro family from /etc/os-release
detect_distro() {
    if [[ ! -f /etc/os-release ]]; then
        error "Cannot detect distribution: /etc/os-release not found"
        exit 1
    fi

    source /etc/os-release

    case "$ID" in
        arch|endeavouros|manjaro|cachyos|garuda)
            DISTRO_FAMILY="arch"
            ;;
        fedora)
            DISTRO_FAMILY="fedora"
            ;;
        ubuntu|debian|linuxmint|pop)
            DISTRO_FAMILY="debian"
            ;;
        *)
            error "Unsupported distribution: $ID"
            exit 1
            ;;
    esac

    info "Detected distro: $ID (family: $DISTRO_FAMILY)"
}

# Install Ansible if not present
install_ansible() {
    if command -v ansible-playbook &>/dev/null; then
        info "Ansible already installed: $(ansible --version | head -1)"
        return
    fi

    info "Installing Ansible..."
    case "$DISTRO_FAMILY" in
        arch)
            sudo pacman -Syu --noconfirm ansible
            ;;
        fedora)
            sudo dnf install -y ansible
            ;;
        debian)
            sudo apt-get update
            sudo apt-get install -y ansible
            ;;
    esac
}

# Install required Ansible collections
install_collections() {
    info "Ensuring required Ansible collections are installed..."
    ansible-galaxy collection install ansible.posix community.general --upgrade
}

# Main
detect_distro
install_ansible
install_collections

MODE="${1:-deploy}"
PROFILE="${2:-full}"
PROFILE_ARGS=(-e "package_profile=$PROFILE")

case "$MODE" in
    save)
        info "Saving current configs into repo..."
        ansible-playbook save.yml
        ;;
    packages)
        info "Installing packages only (profile: $PROFILE)..."
        ansible-playbook site.yml --tags packages --ask-become-pass "${PROFILE_ARGS[@]}"
        ;;
    configs)
        info "Restoring configs only..."
        ansible-playbook site.yml --tags configs
        ;;
    deploy)
        info "Full deployment (profile: $PROFILE)..."
        ansible-playbook site.yml --ask-become-pass "${PROFILE_ARGS[@]}"
        ;;
    *)
        echo "Usage: $0 [deploy|save|packages|configs] [profile]"
        echo ""
        echo "  deploy    Full deployment (default): install packages, restore configs, enable services"
        echo "  save      Save current system configs into the repo"
        echo "  packages  Only install packages"
        echo "  configs   Only restore configs"
        echo ""
        echo "Profiles (default: full):"
        echo "  full      Everything: desktop, browser, chat, voip, gaming, development, shell"
        echo "  laptop    No gaming or voip: desktop, browser, chat, development, shell"
        echo "  minimal   Bare essentials: desktop, shell"
        exit 1
        ;;
esac

if [[ "$MODE" == "deploy" ]]; then
    info "Done! Reboot the system to apply all changes."
else
    info "Done!"
fi
