#!/bin/bash

loading() {
    local t="$1"
    local s="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    for ((i=0;i<5;i++)); do for ((j=0;j<${#s};j++)); do echo -ne "\r  ${s:$j:1} ${t}..."; sleep 0.05; done; done
    echo -ne "\r  DONE: ${t}\n"
}

center() { printf "  %s\n" "$1"; }

clear
echo ""
center "404 NOT FOUND GCP - FULL DEPLOYER"
center "MADE BY SAEKA TOJIRP"
center "fb.com/saekacutiee"
echo ""

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
center "PROJECT: ${PROJECT_ID}"
echo ""

center "SELECT DEPLOYMENT:"
echo ""
center "1) CREATE 4 PROTOCOLS (Trojan/VMess/VLESS/SS)"
center "2) CREATE SSH (WebSocket + VM)"
center "3) CREATE OVPN (OpenVPN VM)"
center "4) CREATE ALL (4 Protocols + SSH + OVPN)"
center "5) MANAGE SSH VM"
echo ""
read -r -p "  CHOICE [4]: " DEPLOY_CHOICE
DEPLOY_CHOICE=${DEPLOY_CHOICE:-4}

case "$DEPLOY_CHOICE" in
    1)
        echo ""
        center "DEPLOYING 4 PROTOCOLS TO CLOUD RUN"
        bash deploy.sh
        ;;
    2)
        echo ""
        center "DEPLOYING SSH"
        echo ""
        center "1) SSH over WebSocket (Cloud Run)"
        center "2) SSH VM (Compute Engine)"
        center "3) BOTH"
        echo ""
        read -r -p "  CHOICE [3]: " SSH_CHOICE
        SSH_CHOICE=${SSH_CHOICE:-3}
        case "$SSH_CHOICE" in
            1) center "SSH over WebSocket is included in the 4 Protocols deployment. Run option 1.";;
            2) bash ssh-vm.sh;;
            3) center "SSH over WebSocket is included in the 4 Protocols deployment."; bash ssh-vm.sh;;
        esac
        ;;
    3)
        echo ""
        center "DEPLOYING OVPN VM"
        bash ovpn-vm.sh
        ;;
    4)
        echo ""
        center "[1/3] DEPLOYING 4 PROTOCOLS + SSH (Cloud Run)"
        bash deploy.sh
        echo ""
        center "[2/3] DEPLOYING SSH VM (Compute Engine)"
        bash ssh-vm.sh
        echo ""
        center "[3/3] DEPLOYING OVPN VM (Compute Engine)"
        bash ovpn-vm.sh
        echo ""
        center "ALL SERVICES DEPLOYED SUCCESSFULLY"
        ;;
    5)
        echo ""
        center "MANAGING SSH VM"
        bash ssh-vm.sh
        ;;
esac
