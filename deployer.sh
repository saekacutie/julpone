#!/bin/bash
BOLD='\033[1m'; RESET='\033[0m'
GREEN='\033[1;32m'; RED='\033[1;31m'; CYAN='\033[1;36m'
YELLOW='\033[1;33m'; MAGENTA='\033[1;35m'; WHITE='\033[1;37m'; BLUE='\033[1;34m'

loading() {
    local t="$1"
    local s="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    for ((i=0;i<5;i++)); do for ((j=0;j<${#s};j++)); do echo -ne "\r  ${CYAN}${s:$j:1} ${t}...${RESET}"; sleep 0.05; done; done
    echo -ne "\r  ${GREEN}DONE: ${t}${RESET}\n"
}

center() { printf "  %s\n" "$1"; }

clear
echo ""
center "${BOLD}${WHITE}╔══════════════════════════════════════════════╗${RESET}"
center "${BOLD}${WHITE}║${RESET}     ${CYAN}404 NOT FOUND GCP — FULL DEPLOYER${RESET}${BOLD}${WHITE}        ║${RESET}"
center "${BOLD}${WHITE}║${RESET}     ${MAGENTA}MADE BY SAEKA TOJIRP${RESET}${BOLD}${WHITE}                  ║${RESET}"
center "${BOLD}${WHITE}║${RESET}     ${GREEN}fb.com/saekacutiee${RESET}${BOLD}${WHITE}                     ║${RESET}"
center "${BOLD}${WHITE}╚══════════════════════════════════════════════╝${RESET}"
echo ""

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
center "${CYAN}PROJECT: ${GREEN}${PROJECT_ID}${RESET}"
echo ""

echo -e "  ${CYAN}SELECT DEPLOYMENT:${RESET}"
echo -e "  ${YELLOW}1) CREATE 4 PROTOCOLS (Trojan/VMess/VLESS/SS)${RESET}"
echo -e "  ${YELLOW}2) CREATE SSH (WebSocket + VM)${RESET}"
echo -e "  ${YELLOW}3) CREATE OVPN (OpenVPN VM)${RESET}"
echo -e "  ${YELLOW}4) CREATE ALL (4 Protocols + SSH + OVPN)${RESET}"
echo -e "  ${YELLOW}5) MANAGE SSH VM${RESET}"
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
        echo -e "  ${CYAN}SELECT SSH TYPE:${RESET}"
        echo -e "  ${YELLOW}1) SSH over WebSocket (Cloud Run)${RESET}"
        echo -e "  ${YELLOW}2) SSH VM (Compute Engine)${RESET}"
        echo -e "  ${YELLOW}3) BOTH${RESET}"
        echo ""
        read -r -p "$(echo -e "  ${CYAN}CHOICE [3]: ${RESET}")" SSH_CHOICE
        SSH_CHOICE=${SSH_CHOICE:-3}
        case "$SSH_CHOICE" in
            1) center "${GREEN}SSH over WebSocket is included in the 4 Protocols deployment. Run option 1.${RESET}";;
            2) bash ssh-vm.sh;;
            3)
                center "${GREEN}SSH over WebSocket is included in the 4 Protocols deployment.${RESET}"
                center "${CYAN}Now deploying SSH VM...${RESET}"
                bash ssh-vm.sh
                ;;
        esac
        ;;
    3)
        echo ""
        center "${CYAN}DEPLOYING OVPN VM${RESET}"
        bash ovpn-vm.sh
        ;;
    4)
        echo ""
        center "${CYAN}DEPLOYING ALL SERVICES${RESET}"
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
