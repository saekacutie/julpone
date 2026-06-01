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
center "${BOLD}${WHITE}SSH VM DEPLOYER${RESET}"
center "${MAGENTA}404 NOT FOUND GCP${RESET}"
center "${GREEN}fb.com/saekacutiee${RESET}"
echo ""

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
center "${CYAN}PROJECT: ${GREEN}${PROJECT_ID}${RESET}"
echo ""

center "${CYAN}SELECT ACTION:${RESET}"
echo ""
center "${YELLOW}1) CREATE SSH VM${RESET}"
center "${YELLOW}2) ADD SSH USER${RESET}"
center "${YELLOW}3) DELETE SSH USER${RESET}"
center "${YELLOW}4) BLOCK SSH USER${RESET}"
center "${YELLOW}5) SET SERVER MESSAGE${RESET}"
center "${YELLOW}6) ENABLE LOW LATENCY${RESET}"
center "${YELLOW}7) LIST USERS${RESET}"
center "${YELLOW}8) DELETE VM${RESET}"
echo ""
read -r -p "$(echo -e "  ${CYAN}CHOICE [1]: ${RESET}")" ACTION_CHOICE
ACTION_CHOICE=${ACTION_CHOICE:-1}

INSTANCE_NAME="ssh-vm"
ZONE="us-central1-a"
MACHINE_TYPE="e2-medium"
SSH_PORT="22"
PASSWORD="saeka-tojirp"

case "$ACTION_CHOICE" in
    1)
        echo ""
        read -r -p "$(echo -e "  ${CYAN}INSTANCE NAME [ssh-vm]: ${RESET}")" INPUT_NAME
        INSTANCE_NAME=${INPUT_NAME:-ssh-vm}

        echo ""
        center "${CYAN}SELECT MACHINE TYPE:${RESET}"
        center "${YELLOW}1) BASIC     (e2-micro, 1 vCPU, 1 GB)${RESET}"
        center "${YELLOW}2) MEDIUM    (e2-medium, 1 vCPU, 4 GB)${RESET}"
        center "${YELLOW}3) HIGH      (e2-standard-2, 2 vCPU, 8 GB)${RESET}"
        center "${YELLOW}4) ULTRA     (e2-standard-4, 4 vCPU, 16 GB)${RESET}"
        echo ""
        read -r -p "$(echo -e "  ${CYAN}CHOICE [2]: ${RESET}")" MACHINE_CHOICE
        case "$MACHINE_CHOICE" in
            1) MACHINE_TYPE="e2-micro";;
            3) MACHINE_TYPE="e2-standard-2";;
            4) MACHINE_TYPE="e2-standard-4";;
            *) MACHINE_TYPE="e2-medium";;
        esac

        echo ""
        center "${CYAN}SELECT SSH PORT:${RESET}"
        center "${YELLOW}1) 22  (Standard)${RESET}"
        center "${YELLOW}2) 443 (Alternative)${RESET}"
        echo ""
        read -r -p "$(echo -e "  ${CYAN}CHOICE [1]: ${RESET}")" PORT_CHOICE
        if [ "$PORT_CHOICE" = "2" ]; then SSH_PORT="443"; fi

        echo ""
        loading "ENABLING COMPUTE API"
        gcloud services enable compute.googleapis.com --project="$PROJECT_ID" --quiet 2>/dev/null

        loading "CREATING FIREWALL"
        gcloud compute firewall-rules create "allow-ssh-${SSH_PORT}-${INSTANCE_NAME}" \
          --project="$PROJECT_ID" --direction=INGRESS --priority=1000 \
          --network=default --action=ALLOW --rules="tcp:${SSH_PORT}" \
          --source-ranges=0.0.0.0/0 --target-tags=ssh-vm --quiet 2>/dev/null

        loading "CREATING VM"
        gcloud compute instances create "$INSTANCE_NAME" \
          --project="$PROJECT_ID" --zone="$ZONE" --machine-type="$MACHINE_TYPE" \
          --image-family=ubuntu-2204-lts --image-project=ubuntu-os-cloud \
          --boot-disk-size=10GB --tags=ssh-vm \
          --metadata=startup-script="#!/bin/bash
            apt update -qq && apt install -y -qq openssh-server
            useradd -m -s /bin/bash saeka 2>/dev/null
            echo 'saeka:${PASSWORD}' | chpasswd
            usermod -aG sudo saeka
            echo 'root:${PASSWORD}' | chpasswd
            mkdir -p /run/sshd
            sed -i 's/#Port 22/Port ${SSH_PORT}/' /etc/ssh/sshd_config
            sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
            echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
            echo 'UseDNS no' >> /etc/ssh/sshd_config
            echo 'GSSAPIAuthentication no' >> /etc/ssh/sshd_config
            echo 'TCPKeepAlive yes' >> /etc/ssh/sshd_config
            echo 'ClientAliveInterval 30' >> /etc/ssh/sshd_config
            echo 'ClientAliveCountMax 3' >> /etc/ssh/sshd_config
            cat > /etc/ssh/banner << 'BEOF'
  ##############################
  #  404 NOT FOUND GCP         #
  #  SAEKA TOJIRP              #
  ##############################
BEOF
            echo 'Banner /etc/ssh/banner' >> /etc/ssh/sshd_config
            systemctl restart sshd 2>/dev/null || service ssh restart 2>/dev/null
" --quiet 2>/dev/null

        VM_IP=$(gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" --format='get(networkInterfaces[0].accessConfigs[0].natIP)' 2>/dev/null)
        if [ -z "$VM_IP" ]; then
            sleep 10
            VM_IP=$(gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" --format='get(networkInterfaces[0].accessConfigs[0].natIP)' 2>/dev/null)
        fi

        echo ""
        center "${GREEN}VM CREATED${RESET}"
        echo ""
        center "${CYAN}IP:   ${GREEN}${VM_IP}${RESET}"
        center "${CYAN}PORT: ${GREEN}${SSH_PORT}${RESET}"
        center "${CYAN}USER: ${GREEN}saeka${RESET}"
        center "${CYAN}PASS: ${GREEN}${PASSWORD}${RESET}"
        center "${CYAN}SSH:  ${GREEN}ssh saeka@${VM_IP} -p ${SSH_PORT}${RESET}"
        ;;
    2)
        echo ""
        read -r -p "$(echo -e "  ${CYAN}VM NAME [ssh-vm]: ${RESET}")" INSTANCE_NAME
        INSTANCE_NAME=${INSTANCE_NAME:-ssh-vm}
        read -r -p "$(echo -e "  ${CYAN}NEW USERNAME: ${RESET}")" NEW_USER
        read -r -p "$(echo -e "  ${CYAN}NEW PASSWORD: ${RESET}")" NEW_PASS
        gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" --command="sudo useradd -m -s /bin/bash $NEW_USER && echo '$NEW_USER:$NEW_PASS' | sudo chpasswd && echo 'User $NEW_USER added'" 2>/dev/null
        center "${GREEN}USER $NEW_USER ADDED${RESET}"
        ;;
    3)
        echo ""
        read -r -p "$(echo -e "  ${CYAN}VM NAME [ssh-vm]: ${RESET}")" INSTANCE_NAME
        INSTANCE_NAME=${INSTANCE_NAME:-ssh-vm}
        read -r -p "$(echo -e "  ${CYAN}USERNAME TO DELETE: ${RESET}")" DEL_USER
        gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" --command="sudo userdel -r $DEL_USER 2>/dev/null && echo 'User $DEL_USER deleted'" 2>/dev/null
        center "${RED}USER $DEL_USER DELETED${RESET}"
        ;;
    4)
        echo ""
        read -r -p "$(echo -e "  ${CYAN}VM NAME [ssh-vm]: ${RESET}")" INSTANCE_NAME
        INSTANCE_NAME=${INSTANCE_NAME:-ssh-vm}
        read -r -p "$(echo -e "  ${CYAN}USERNAME TO BLOCK: ${RESET}")" BLOCK_USER
        gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" --command="sudo usermod -L $BLOCK_USER && echo 'User $BLOCK_USER blocked'" 2>/dev/null
        center "${RED}USER $BLOCK_USER BLOCKED${RESET}"
        ;;
    5)
        echo ""
        read -r -p "$(echo -e "  ${CYAN}VM NAME [ssh-vm]: ${RESET}")" INSTANCE_NAME
        INSTANCE_NAME=${INSTANCE_NAME:-ssh-vm}
        echo ""
        center "${CYAN}ENTER SERVER MESSAGE (type DONE on a new line to finish):${RESET}"
        MSG_FILE="/tmp/banner_msg_$$"
        > "$MSG_FILE"
        while read -r line; do
            if [ "$line" = "DONE" ]; then break; fi
            echo "$line" >> "$MSG_FILE"
        done
        gcloud compute scp "$MSG_FILE" "${INSTANCE_NAME}:/tmp/banner_msg" --zone="$ZONE" --project="$PROJECT_ID" --quiet 2>/dev/null
        gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" --command="sudo cp /tmp/banner_msg /etc/ssh/banner && sudo systemctl restart sshd" 2>/dev/null
        center "${GREEN}BANNER UPDATED${RESET}"
        rm -f "$MSG_FILE"
        ;;
    6)
        echo ""
        read -r -p "$(echo -e "  ${CYAN}VM NAME [ssh-vm]: ${RESET}")" INSTANCE_NAME
        INSTANCE_NAME=${INSTANCE_NAME:-ssh-vm}
        gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" --command="sudo sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config && sudo sed -i 's/#GSSAPIAuthentication yes/GSSAPIAuthentication no/' /etc/ssh/sshd_config && echo 'TCPKeepAlive yes' | sudo tee -a /etc/ssh/sshd_config && echo 'ClientAliveInterval 15' | sudo tee -a /etc/ssh/sshd_config && sudo systemctl restart sshd && echo 'Low latency enabled'" 2>/dev/null
        center "${GREEN}LOW LATENCY ENABLED${RESET}"
        ;;
    7)
        echo ""
        read -r -p "$(echo -e "  ${CYAN}VM NAME [ssh-vm]: ${RESET}")" INSTANCE_NAME
        INSTANCE_NAME=${INSTANCE_NAME:-ssh-vm}
        gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" --command="cut -d: -f1 /etc/passwd | grep -v '^#' | tail -n +10" 2>/dev/null
        ;;
    8)
        echo ""
        read -r -p "$(echo -e "  ${CYAN}VM NAME [ssh-vm]: ${RESET}")" INSTANCE_NAME
        INSTANCE_NAME=${INSTANCE_NAME:-ssh-vm}
        read -r -p "$(echo -e "  ${RED}DELETE VM $INSTANCE_NAME? (yes/no): ${RESET}")" CONFIRM
        if [ "$CONFIRM" = "yes" ]; then
            gcloud compute instances delete "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" --quiet 2>/dev/null
            center "${RED}VM DELETED${RESET}"
        else
            center "${CYAN}CANCELLED${RESET}"
        fi
        ;;
esac
