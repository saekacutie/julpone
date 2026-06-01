#!/bin/bash

BOLD="\033[1m"
RESET="\033[0m"
GREEN="\033[1;32m"
RED="\033[1;31m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
MAGENTA="\033[1;35m"
WHITE="\033[1;37m"

loading() {
    local t="$1"
    local s="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    for ((i=0;i<5;i++)); do for ((j=0;j<${#s};j++)); do
        printf "\r  ${CYAN}${s:$j:1} ${t}...${RESET}"
        sleep 0.05
    done; done
    printf "\r  ${GREEN}DONE: ${t}${RESET}\n"
}

center() { printf "  ${1}\n"; }

clear
echo ""
center "${BOLD}${WHITE}404 NOT FOUND GCP DEPLOYER v3.0${RESET}"
center "${MAGENTA}MADE BY SAEKA TOJIRP${RESET}"
center "${GREEN}fb.com/saekacutiee${RESET}"
echo ""

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
center "${CYAN}PROJECT: ${GREEN}${PROJECT_ID}${RESET}"
echo ""

printf "  ${CYAN}SERVICE NAME [prvtspyyy]: ${RESET}"
read -r INPUT_NAME
SERVICE_NAME=${INPUT_NAME:-prvtspyyy}

echo ""
center "${CYAN}SELECT REGION:${RESET}"
center "${YELLOW}1) us-central1       2) us-east1${RESET}"
center "${YELLOW}3) us-west1          4) asia-southeast1${RESET}"
center "${YELLOW}5) asia-east1        6) asia-northeast1${RESET}"
center "${YELLOW}7) europe-west1      8) europe-west4${RESET}"
center "${YELLOW}9) australia-southeast1${RESET}"
echo ""
printf "  ${CYAN}CHOICE [1]: ${RESET}"
read -r REGION_CHOICE
case "$REGION_CHOICE" in
    2) REGION="us-east1";; 3) REGION="us-west1";; 4) REGION="asia-southeast1";;
    5) REGION="asia-east1";; 6) REGION="asia-northeast1";; 7) REGION="europe-west1";;
    8) REGION="europe-west4";; 9) REGION="australia-southeast1";; *) REGION="us-central1";;
esac

echo ""
center "${CYAN}SELECT MODE:${RESET}"
center "${YELLOW}1) BROWSING     2) STREAMING${RESET}"
center "${YELLOW}3) GAMING       4) ULTRA${RESET}"
center "${YELLOW}5) CUSTOM${RESET}"
echo ""
printf "  ${CYAN}CHOICE [4]: ${RESET}"
read -r MODE_CHOICE
case "$MODE_CHOICE" in
    1) CPU="1"; RAM="2Gi"; MAX_INSTANCES="4"; MODE="BROWSING";;
    2) CPU="2"; RAM="4Gi"; MAX_INSTANCES="4"; MODE="STREAMING";;
    3) CPU="4"; RAM="8Gi"; MAX_INSTANCES="4"; MODE="GAMING";;
    5)
        printf "  CPU (1/2/4/8): "; read -r CPU
        printf "  RAM (2Gi/4Gi/8Gi/16Gi/32Gi): "; read -r RAM
        printf "  MAX INSTANCES: "; read -r MAX_INSTANCES
        MODE="CUSTOM"
        ;;
    *) CPU="8"; RAM="32Gi"; MAX_INSTANCES="1"; MODE="ULTRA";;
esac

if [ "$CPU" -ge 8 ] && [ "$MAX_INSTANCES" -gt 2 ]; then
    MAX_INSTANCES="2"
fi

RAM_NUM=$(echo "$RAM" | sed 's/Gi//')
if [ "$RAM_NUM" -ge 16 ] && [ "$MAX_INSTANCES" -gt 1 ]; then
    MAX_INSTANCES="1"
fi

echo ""
center "${CYAN}MODE: ${GREEN}${MODE}${RESET} | ${CYAN}CPU: ${GREEN}${CPU}${RESET} | ${CYAN}RAM: ${GREEN}${RAM}${RESET} | ${CYAN}INSTANCES: ${GREEN}${MAX_INSTANCES}${RESET} | ${CYAN}REGION: ${GREEN}${REGION}${RESET}"

START_TIME=$(date +%s)

echo ""
loading "ENABLING APIS"
gcloud services enable run.googleapis.com cloudbuild.googleapis.com --project="$PROJECT_ID" --quiet 2>/dev/null

loading "BUILDING IMAGE"
gcloud builds submit --tag "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" . --project="$PROJECT_ID" --region="$REGION" --quiet > build.log 2>&1 || { printf "  ${RED}BUILD FAILED${RESET}\n"; tail -n 10 build.log; exit 1; }

loading "DEPLOYING TO CLOUD RUN"
gcloud run deploy "$SERVICE_NAME" \
  --image "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" \
  --platform managed --region "$REGION" \
  --cpu "$CPU" --memory "$RAM" --port 8080 \
  --concurrency 1000 --cpu-boost --no-cpu-throttling \
  --timeout 3600 --min-instances 1 --max-instances "$MAX_INSTANCES" \
  --allow-unauthenticated --project="$PROJECT_ID" --quiet > deploy.log 2>&1 || { printf "  ${RED}DEPLOY FAILED${RESET}\n"; tail -n 10 deploy.log; exit 1; }

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region "$REGION" --project="$PROJECT_ID" --format='value(status.url)' 2>/dev/null)
CLEAN_HOST=$(echo "$SERVICE_URL" | sed 's|https://||')
RUNTIME=$(($(date +%s) - START_TIME))

echo ""
center "${GREEN}DEPLOYED SUCCESSFULLY${RESET}"
echo ""
center "${CYAN}HOST:     ${GREEN}${CLEAN_HOST}${RESET}"
center "${CYAN}PORT:     ${GREEN}443${RESET}"
center "${CYAN}PASS:     ${GREEN}saeka${RESET}"
center "${CYAN}MODE:     ${GREEN}${MODE}${RESET}"
center "${CYAN}CPU:      ${GREEN}${CPU}${RESET}"
center "${CYAN}RAM:      ${GREEN}${RAM}${RESET}"
center "${CYAN}INSTANCES:${GREEN}${MAX_INSTANCES}${RESET}"
center "${CYAN}REGION:   ${GREEN}${REGION}${RESET}"
center "${CYAN}RUNTIME:  ${GREEN}${RUNTIME}s${RESET}"
echo ""
center "${CYAN}TROJAN:      ${GREEN}/saeka-tojirp${RESET}"
center "${CYAN}VMESS:       ${GREEN}/vmess-saeka${RESET}"
center "${CYAN}VLESS:       ${GREEN}/vless-saeka${RESET}"
center "${CYAN}SS:          ${GREEN}/ss-saeka${RESET}"
center "${CYAN}SSH:         ${GREEN}/saeka-ssh${RESET}"
echo ""
center "${CYAN}PAGE:    ${GREEN}${SERVICE_URL}${RESET}"

rm -f build.log deploy.log
