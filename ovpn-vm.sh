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

clear
echo ""
echo -e "  ${BOLD}${WHITE}OPENVPN VM DEPLOYER${RESET}"
echo -e "  ${MAGENTA}404 NOT FOUND GCP${RESET}"
echo -e "  ${GREEN}fb.com/saekacutiee${RESET}"
echo ""

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
echo -e "  ${CYAN}PROJECT: ${GREEN}${PROJECT_ID}${RESET}"
echo ""

read -r -p "$(echo -e "  ${CYAN}INSTANCE NAME [ovpn-vm]: ${RESET}")" INSTANCE_NAME
INSTANCE_NAME=${INSTANCE_NAME:-ovpn-vm}

echo ""
echo -e "  ${CYAN}SELECT MACHINE TYPE:${RESET}"
echo -e "  ${YELLOW}1) BASIC     (e2-micro, 1 vCPU, 1 GB)${RESET}"
echo -e "  ${YELLOW}2) MEDIUM    (e2-medium, 1 vCPU, 4 GB)${RESET}"
echo -e "  ${YELLOW}3) HIGH      (e2-standard-2, 2 vCPU, 8 GB)${RESET}"
echo -e "  ${YELLOW}4) ULTRA     (e2-standard-4, 4 vCPU, 16 GB)${RESET}"
echo ""
read -r -p "$(echo -e "  ${CYAN}CHOICE [2]: ${RESET}")" MACHINE_CHOICE

case "$MACHINE_CHOICE" in
    1) MACHINE_TYPE="e2-micro";;
    3) MACHINE_TYPE="e2-standard-2";;
    4) MACHINE_TYPE="e2-standard-4";;
    *) MACHINE_TYPE="e2-medium";;
esac

echo ""
echo -e "  ${CYAN}SELECT OVPN PORT:${RESET}"
echo -e "  ${YELLOW}1) 1194 (Standard UDP)${RESET}"
echo -e "  ${YELLOW}2) 443  (TCP over HTTPS)${RESET}"
echo ""
read -r -p "$(echo -e "  ${CYAN}CHOICE [2]: ${RESET}")" PORT_CHOICE
OVPN_PORT="443"
OVPN_PROTO="tcp"
if [ "$PORT_CHOICE" = "1" ]; then OVPN_PORT="1194"; OVPN_PROTO="udp"; fi

ZONE="us-central1-a"
OVPN_PASSWORD="saeka-tojirp"

echo ""
loading "ENABLING COMPUTE API"
gcloud services enable compute.googleapis.com --project=$PROJECT_ID --quiet 2>/dev/null

loading "CREATING FIREWALL"
gcloud compute firewall-rules create allow-ovpn-${OVPN_PORT} \
  --project=$PROJECT_ID --direction=INGRESS --priority=1000 \
  --network=default --action=ALLOW --rules=${OVPN_PROTO}:${OVPN_PORT} \
  --source-ranges=0.0.0.0/0 --target-tags=ovpn-vm --quiet 2>/dev/null

loading "CREATING VIRTUAL MACHINE"
gcloud compute instances create "$INSTANCE_NAME" \
  --project=$PROJECT_ID --zone=$ZONE --machine-type=$MACHINE_TYPE \
  --image-family=ubuntu-2204-lts --image-project=ubuntu-os-cloud \
  --boot-disk-size=10GB --tags=ovpn-vm \
  --metadata=startup-script="#!/bin/bash
    apt update -qq && apt install -y -qq openvpn easy-rsa iptables-persistent
    make-cadir /etc/openvpn/easy-rsa
    cd /etc/openvpn/easy-rsa
    ./easyrsa init-pki
    echo 'saeka' | ./easyrsa build-ca nopass
    echo 'saeka' | ./easyrsa gen-req server nopass
    echo 'yes' | ./easyrsa sign-req server server
    ./easyrsa gen-dh
    openvpn --genkey secret ta.key
    echo 'saeka' | ./easyrsa gen-req client nopass
    echo 'yes' | ./easyrsa sign-req client client
    cat > /etc/openvpn/server.conf << 'OVPNCONF'
port ${OVPN_PORT}
proto ${OVPN_PROTO}
dev tun
ca /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
key /etc/openvpn/easy-rsa/pki/private/server.key
dh /etc/openvpn/easy-rsa/pki/dh.pem
tls-auth /etc/openvpn/easy-rsa/ta.key 0
server 10.8.0.0 255.255.255.0
push 'redirect-gateway def1'
push 'dhcp-option DNS 8.8.8.8'
push 'dhcp-option DNS 1.1.1.1'
keepalive 10 60
cipher AES-256-GCM
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn-status.log
log-append /var/log/openvpn.log
verb 0
explicit-exit-notify 1
OVPNCONF
    sysctl -w net.ipv4.ip_forward=1
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
    netfilter-persistent save
    systemctl start openvpn@server
    systemctl enable openvpn@server
    cat > /root/client.ovpn << 'CLIENTEOF'
client
dev tun
proto ${OVPN_PROTO}
remote EXTERNAL_IP ${OVPN_PORT}
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
verb 0
<ca>
CA_CERT_PLACEHOLDER
</ca>
<cert>
CLIENT_CERT_PLACEHOLDER
</cert>
<key>
CLIENT_KEY_PLACEHOLDER
</key>
<tls-auth>
TA_KEY_PLACEHOLDER
</tls-auth>
key-direction 1
CLIENTEOF
    CA_CERT=\$(cat /etc/openvpn/easy-rsa/pki/ca.crt)
    CLIENT_CERT=\$(sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' /etc/openvpn/easy-rsa/pki/issued/client.crt)
    CLIENT_KEY=\$(cat /etc/openvpn/easy-rsa/pki/private/client.key)
    TA_KEY=\$(cat /etc/openvpn/easy-rsa/ta.key)
    sed -i \"s|CA_CERT_PLACEHOLDER|\$CA_CERT|\" /root/client.ovpn
    sed -i \"s|CLIENT_CERT_PLACEHOLDER|\$CLIENT_CERT|\" /root/client.ovpn
    sed -i \"s|CLIENT_KEY_PLACEHOLDER|\$CLIENT_KEY|\" /root/client.ovpn
    sed -i \"s|TA_KEY_PLACEHOLDER|\$TA_KEY|\" /root/client.ovpn
" --quiet 2>/dev/null

VM_IP=$(gcloud compute instances describe "$INSTANCE_NAME" --zone=$ZONE --project=$PROJECT_ID --format='get(networkInterfaces[0].accessConfigs[0].natIP)' 2>/dev/null)
if [ -z "$VM_IP" ]; then sleep 10; VM_IP=$(gcloud compute instances describe "$INSTANCE_NAME" --zone=$ZONE --project=$PROJECT_ID --format='get(networkInterfaces[0].accessConfigs[0].natIP)' 2>/dev/null); fi

echo ""
echo -e "  ${GREEN}OVPN VM CREATED SUCCESSFULLY${RESET}"
echo ""
echo -e "  ${CYAN}IP:       ${GREEN}${VM_IP}${RESET}"
echo -e "  ${CYAN}PORT:     ${GREEN}${OVPN_PORT}${RESET}"
echo -e "  ${CYAN}PROTO:    ${GREEN}${OVPN_PROTO}${RESET}"
echo -e "  ${CYAN}MACHINE:  ${GREEN}${MACHINE_TYPE}${RESET}"
echo ""
echo -e "  ${CYAN}DOWNLOAD CLIENT CONFIG:${RESET}"
echo -e "  ${GREEN}gcloud compute scp root@${INSTANCE_NAME}:/root/client.ovpn ./client.ovpn --zone=${ZONE}${RESET}"
echo ""
echo -e "  ${CYAN}OR SSH INTO VM AND COPY:${RESET}"
echo -e "  ${GREEN}gcloud compute ssh ${INSTANCE_NAME} --zone=${ZONE}${RESET}"
echo -e "  ${GREEN}sudo cat /root/client.ovpn${RESET}"
