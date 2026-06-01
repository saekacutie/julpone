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
echo -e "  ${BOLD}${WHITE}404 NOT FOUND GCP DEPLOYER v3.0${RESET}"
echo -e "  ${MAGENTA}MADE BY SAEKA TOJIRP${RESET}"
echo -e "  ${GREEN}fb.com/saekacutiee${RESET}"
echo ""

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
echo -e "  ${CYAN}PROJECT: ${GREEN}${PROJECT_ID}${RESET}"
echo ""

read -r -p "$(echo -e "  ${CYAN}SERVICE NAME [prvtspyyy]: ${RESET}")" INPUT_NAME
SERVICE_NAME=${INPUT_NAME:-prvtspyyy}

echo ""
echo -e "  ${CYAN}SELECT REGION:${RESET}"
echo -e "  ${YELLOW}1) us-central1       2) us-east1${RESET}"
echo -e "  ${YELLOW}3) us-west1          4) asia-southeast1${RESET}"
echo -e "  ${YELLOW}5) asia-east1        6) asia-northeast1${RESET}"
echo -e "  ${YELLOW}7) europe-west1      8) europe-west4${RESET}"
echo -e "  ${YELLOW}9) australia-southeast1${RESET}"
echo ""
read -r -p "$(echo -e "  ${CYAN}CHOICE [1]: ${RESET}")" REGION_CHOICE
case "$REGION_CHOICE" in
    2) REGION="us-east1";; 3) REGION="us-west1";; 4) REGION="asia-southeast1";;
    5) REGION="asia-east1";; 6) REGION="asia-northeast1";; 7) REGION="europe-west1";;
    8) REGION="europe-west4";; 9) REGION="australia-southeast1";; *) REGION="us-central1";;
esac

echo ""
echo -e "  ${CYAN}SELECT MODE:${RESET}"
echo -e "  ${YELLOW}1) BROWSING     2) STREAMING${RESET}"
echo -e "  ${YELLOW}3) GAMING       4) ULTRA${RESET}"
echo -e "  ${YELLOW}5) CUSTOM${RESET}"
echo ""
read -r -p "$(echo -e "  ${CYAN}CHOICE [4]: ${RESET}")" MODE_CHOICE
case "$MODE_CHOICE" in
    1) CPU="1"; RAM="2Gi"; MAX_INSTANCES="1"; MODE="BROWSING";;
    2) CPU="2"; RAM="4Gi"; MAX_INSTANCES="2"; MODE="STREAMING";;
    3) CPU="4"; RAM="8Gi"; MAX_INSTANCES="4"; MODE="GAMING";;
    5) read -r -p "  CPU (1/2/4/8): " CPU; read -r -p "  RAM: " RAM; read -r -p "  MAX INSTANCES: " MAX_INSTANCES; MODE="CUSTOM";;
    *) CPU="8"; RAM="16Gi"; MAX_INSTANCES="8"; MODE="ULTRA";;
esac

echo ""
echo -e "  ${CYAN}MODE: ${GREEN}${MODE}${RESET} | ${CYAN}CPU: ${GREEN}${CPU}${RESET} | ${CYAN}RAM: ${GREEN}${RAM}${RESET} | ${CYAN}INSTANCES: ${GREEN}${MAX_INSTANCES}${RESET} | ${CYAN}REGION: ${GREEN}${REGION}${RESET}"

START_TIME=$(date +%s)

echo ""
loading "ENABLING APIS"
gcloud services enable run.googleapis.com cloudbuild.googleapis.com --project=$PROJECT_ID --quiet 2>/dev/null

loading "BUILDING IMAGE"
gcloud builds submit --tag "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" . --project=$PROJECT_ID --region=$REGION --quiet > build.log 2>&1 || { echo -e "  ${RED}BUILD FAILED${RESET}"; tail -n 10 build.log; exit 1; }

loading "DEPLOYING TO CLOUD RUN"
gcloud run deploy "$SERVICE_NAME" \
  --image "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" \
  --platform managed --region "$REGION" \
  --cpu "$CPU" --memory "$RAM" --port 8080 \
  --concurrency 1000 --cpu-boost --no-cpu-throttling \
  --timeout 3600 --min-instances 1 --max-instances "$MAX_INSTANCES" \
  --allow-unauthenticated --project=$PROJECT_ID --quiet > deploy.log 2>&1 || { echo -e "  ${RED}DEPLOY FAILED${RESET}"; tail -n 10 deploy.log; exit 1; }

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region "$REGION" --project=$PROJECT_ID --format='value(status.url)' 2>/dev/null)
CLEAN_HOST=$(echo "$SERVICE_URL" | sed 's|https://||')
RUNTIME=$(($(date +%s) - START_TIME))

echo ""
echo -e "  ${GREEN}DEPLOYED SUCCESSFULLY${RESET}"
echo ""
echo -e "  ${CYAN}HOST:     ${GREEN}${CLEAN_HOST}${RESET}"
echo -e "  ${CYAN}PORT:     ${GREEN}443${RESET}"
echo -e "  ${CYAN}PASS:     ${GREEN}saeka${RESET}"
echo -e "  ${CYAN}MODE:     ${GREEN}${MODE}${RESET}"
echo -e "  ${CYAN}CPU:      ${GREEN}${CPU}${RESET}"
echo -e "  ${CYAN}RAM:      ${GREEN}${RAM}${RESET}"
echo -e "  ${CYAN}INSTANCES:${GREEN}${MAX_INSTANCES}${RESET}"
echo -e "  ${CYAN}REGION:   ${GREEN}${REGION}${RESET}"
echo -e "  ${CYAN}RUNTIME:  ${GREEN}${RUNTIME}s${RESET}"
echo ""
echo -e "  ${CYAN}TROJAN:      ${GREEN}/saeka-tojirp${RESET}"
echo -e "  ${CYAN}VMESS:       ${GREEN}/vmess-saeka${RESET}"
echo -e "  ${CYAN}VLESS:       ${GREEN}/vless-saeka${RESET}"
echo -e "  ${CYAN}SS:          ${GREEN}/ss-saeka${RESET}"
echo -e "  ${CYAN}SSH:         ${GREEN}/saeka-ssh${RESET}"
echo ""
echo -e "  ${CYAN}PAGE:    ${GREEN}${SERVICE_URL}${RESET}"

rm -f build.log deploy.log
