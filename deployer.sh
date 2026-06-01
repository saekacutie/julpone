#!/bin/bash
BOLD='\033[1m'; RESET='\033[0m'
GREEN='\033[1;32m'; RED='\033[1;31m'; CYAN='\033[1;36m'
YELLOW='\033[1;33m'; MAGENTA='\033[1;35m'; WHITE='\033[1;37m'

loading() {
    local t="$1"
    local s="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    for ((i=0;i<5;i++)); do for ((j=0;j<${#s};j++)); do echo -ne "\r  ${CYAN}${s:$j:1} ${t}...${RESET}"; sleep 0.05; done; done
    echo -ne "\r  ${GREEN}DONE: ${t}${RESET}\n"
}

center() { printf "  %s\n" "$1"; }

clear
echo ""
center "${BOLD}${WHITE}404 NOT FOUND GCP - FULL DEPLOYER${RESET}"
center "${MAGENTA}MADE BY SAEKA TOJIRP${RESET}"
center "${GREEN}fb.com/saekacutiee${RESET}"
echo ""

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
center "${CYAN}PROJECT: ${GREEN}${PROJECT_ID}${RESET}"
echo ""

center "${CYAN}SELECT DEPLOYMENT:${RESET}"
echo ""
center "${YELLOW}1) CREATE 4 PROTOCOLS (Trojan/VMess/VLESS/SS)${RESET}"
center "${YELLOW}2) CREATE SSH (WebSocket + VM)${RESET}"
center "${YELLOW}3) CREATE OVPN (OpenVPN VM)${RESET}"
center "${YELLOW}4) CREATE ALL (4 Protocols + SSH + OVPN)${RESET}"
center "${YELLOW}5) MANAGE SSH VM${RESET}"
echo ""
read -r -p "$(echo -e "  ${CYAN}CHOICE [4]: ${RESET}")" DEPLOY_CHOICE
DEPLOY_CHOICE=${DEPLOY_CHOICE:-4}

case "$DEPLOY_CHOICE" in
    1)
        echo ""
        center "${CYAN}DEPLOYING 4 PROTOCOLS TO CLOUD RUN${RESET}"
        bash deploy.sh
        ;;
    2)
        echo ""
        center "${CYAN}DEPLOYING SSH${RESET}"
        echo ""
        center "${YELLOW}1) SSH over WebSocket (Cloud Run)${RESET}"
        center "${YELLOW}2) SSH VM (Compute Engine)${RESET}"
        center "${YELLOW}3) BOTH${RESET}"
        echo ""
        read -r -p "$(echo -e "  ${CYAN}CHOICE [3]: ${RESET}")" SSH_CHOICE
        SSH_CHOICE=${SSH_CHOICE:-3}
        case "$SSH_CHOICE" in
            1) center "${GREEN}SSH over WebSocket is included in the 4 Protocols deployment. Run option 1.${RESET}";;
            2) bash ssh-vm.sh;;
            3) center "${GREEN}SSH over WebSocket is included in the 4 Protocols deployment.${RESET}"; bash ssh-vm.sh;;
        esac
        ;;
    3)
        echo ""
        center "${CYAN}DEPLOYING OVPN VM${RESET}"
        bash ovpn-vm.sh
        ;;
    4)
        echo ""
        center "${MAGENTA}[1/3] DEPLOYING 4 PROTOCOLS + SSH (Cloud Run)${RESET}"
        bash deploy.sh
        echo ""
        center "${MAGENTA}[2/3] DEPLOYING SSH VM (Compute Engine)${RESET}"
        bash ssh-vm.sh
        echo ""
        center "${MAGENTA}[3/3] DEPLOYING OVPN VM (Compute Engine)${RESET}"
        bash ovpn-vm.sh
        echo ""
        center "${GREEN}ALL SERVICES DEPLOYED SUCCESSFULLY${RESET}"
        ;;
    5)
        echo ""
        center "${CYAN}MANAGING SSH VM${RESET}"
        bash ssh-vm.sh
        ;;
esac
