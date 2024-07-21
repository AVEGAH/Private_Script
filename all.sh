#!/bin/bash

# Telegram bot token and chat ID
BOT_TOKEN="7380565425:AAFFIJ_GOhqWkC4ANzQTEiR06v6CBXtlL7g"
CHANNEL_ID="-1002148915754"

# URL to fetch allowed IP list
ALLOWED_IP_URL="https://raw.githubusercontent.com/AVEGAH/null/main/dell.txt"

# Define the list of commands
declare -A scripts
scripts["SSH"]="apt-get update -y; apt-get upgrade -y; wget https://raw.githubusercontent.com/AVEGAH/MAPTECH-VPS-MANAGER/main/hehe; chmod 777 hehe; ./hehe"
scripts["UDP REQUEST"]="wget https://raw.githubusercontent.com/AVEGAH/SocksIP-udpServer/main/UDPserver.sh; chmod +x UDPserver.sh; ./UDPserver.sh"
scripts["UDP CUSTOM"]="git clone https://github.com/AVEGAH/Udpcustom.git && cd Udpcustom && chmod +x install.sh && ./install.sh"
scripts["UDP HYSTERIA"]="wget https://github.com/khaledagn/AGN-UDP/raw/main/install_agnudp.sh; chmod +x install_agnudp.sh; ./install_agnudp.sh; nano /etc/hysteria/config.json"
scripts["HIDDIFY NEXT"]="bash <(curl -Ls https://raw.githubusercontent.com/ozipoetra/z-ui/main/install.sh)"
scripts["Autoscript"]="sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sysctl -w net.ipv6.conf.default.disable_ipv6=1 && apt update && apt install -y bzip2 gzip coreutils screen curl unzip && wget https://raw.githubusercontent.com/AVEGAH/AutoScriptXray/master/setup.sh && chmod +x setup.sh && sed -i -e 's/\r$//' setup.sh && screen -S setup ./setup.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verification storage directory and file
VCHECK_DIR="/root/vcheck"
VCHECK_FILE="$VCHECK_DIR/.storage.txt"

# Function to clear screen
clear_screen() {
    clear
}

# ASCII Art Header
show_header() {
    clear_screen
    echo -e "${BLUE}"
    echo "   ███╗   ███╗ █████╗ ██████╗ ████████╗███████╗ ██████╗██╗  ██╗"
    echo "   ████╗ ████║██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔════╝██║  ██║"
    echo "   ██╔████╔██║███████║██████╔╝   ██║   █████╗  ██║     ███████║"
    echo "   ██║╚██╔╝██║██╔══██║██╔═══╝    ██║   ██╔══╝  ██║     ██╔══██║"
    echo "   ██║ ╚═╝ ██║██║  ██║██║        ██║   ███████╗╚██████╗██║  ██║"
    echo "   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝        ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝"
    echo -e "${NC}"
}

# Function to fetch the user's IP address
fetch_user_ip() {
    user_ip=$(curl -s ifconfig.me)
    echo "User IP: $user_ip"
}

# Function to fetch the allowed IP list
fetch_allowed_ips() {
    allowed_ips=$(curl -s "$ALLOWED_IP_URL" || echo "")
    echo "Allowed IPs: $allowed_ips"
}

# Function to check if the user's IP is in the allowed list
validate_ip() {
    fetch_user_ip
    fetch_allowed_ips

    # Debug output for fetched IPs
    echo "User IP: $user_ip"
    echo "Allowed IPs: $allowed_ips"

    # Check if user IP is in the allowed list
    if echo "$allowed_ips" | grep -w "$user_ip" >/dev/null; then
        echo -e "${GREEN}IP address validation successful.${NC}"
        install_selected_script
    else
        echo -e "${RED}IP address validation failed. Your IP ($user_ip) is not allowed to run this script.${NC}"
        exit 1
    fi
}

# Function to send message via Telegram including IPv4 address
send_telegram_message() {
    local message="$1"
    local url="https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
    local data="chat_id=$CHANNEL_ID&text=$message"
    
    # Send the message
    response=$(curl -s -w "%{http_code}" -o /dev/null -d "$data" "$url")
    
    # Check for success response
    if [[ "$response" -eq 200 ]]; then
        echo "Message sent successfully."
    else
        echo -e "${RED}Failed to send message. HTTP status code: $response${NC}"
        exit 1
    fi
}

# Function to send verification code via Telegram
send_verification_code() {
    # Generate random 6-digit verification code
    verification_code=$(shuf -i 100000-999999 -n 1)

    # Get the IPv4 address
    ipv4_address=$(hostname -I | awk '{print $1}')

    # Create the vcheck directory and storage file if they do not exist
    mkdir -p "$VCHECK_DIR"
    touch "$VCHECK_FILE"
    chmod 600 "$VCHECK_FILE"  # Restrict permissions for security

    local current_time=$(date +%s)

    # Check if there's a recent request from the same IP address
    local last_sent_code=$(awk -v ip="$ipv4_address" '$1 == ip {print $2}' "$VCHECK_FILE")
    local last_sent_time=$(awk -v ip="$ipv4_address" '$1 == ip {print $3}' "$VCHECK_FILE")

    # Adjust the time interval here (e.g., 600 for 10 minutes)
    if [[ -n "$last_sent_code" && $((current_time - last_sent_time)) -lt 3600 ]]; then
        # Calculate remaining time in seconds
        local time_left=$((3600 - (current_time - last_sent_time)))

        # Convert remaining time to minutes and seconds
        local minutes=$((time_left / 60))
        local seconds=$((time_left % 60))

        # Display the message with the remaining time
        echo -e "\033[1;36m======================================================================================\033[0m"
        echo -e "\033[1;31m  CODE SENT ALREADY! YOU HAVE $minutes MINUTES AND $seconds SECONDS LEFT TO REDEEM IT \033[0m"
        echo -e "\033[1;36m======================================================================================\033[0m"
        echo ""
        echo -e "\033[1;32m              t.me/maptechvpsscriptbot  \033[0m on Telegram"
        echo ""
        echo -e "\033[1;36m======================================================================================\033[0m"
        echo ""
        read -p "Enter the verification code received: " user_code
        check_verification_code "$user_code"
        return
    fi

    # Send verification code via Telegram
    send_telegram_message "The verification code for $ipv4_address is: $verification_code"

    # Display contact information for verification code
    echo -e "\033[1;36m==============================================================\033[0m"
    echo -e "\033[1;31m          ALL IN ONE VPS SCRIPT INSTALLATION\033[0m"
    echo -e "\033[1;36m==============================================================\033[0m"
    echo ""
    echo -e "\033[1;32m              t.me/wmaptechvpsscriptbot  \033[0m on Telegram"
    echo ""
    echo -e "\033[1;36m==============================================================\033[0m"
    echo ""
    echo -e "\033[1;31m  Get the verification code from our Telegram bot {T & C}  \033[0m"
    echo ""

    # Prompt user for verification code
    read -p "Enter the verification code received: " user_code

    # Check if user entered the correct verification code
    if [[ "$user_code" == "$verification_code" ]]; then
        echo -e "${GREEN}Verification successful.${NC}"
        # Store the code along with the IP address and current time in the storage file
        echo "$ipv4_address $verification_code $current_time" >> "$VCHECK_FILE"
        install_selected_script
    else
        echo -e "${RED}Incorrect verification code.${NC}"
        send_verification_code
    fi
}

# Function to check the verification code entered by the user
check_verification_code() {
    local user_code=$1
    local stored_code=$(awk -v ip="$ipv4_address" '$1 == ip {print $2}' "$VCHECK_FILE")
    if [[ "$user_code" == "$stored_code" ]]; then
        echo -e "${GREEN}Verification successful.${NC}"
        install_selected_script
    else
        echo -e "${RED}Incorrect verification code.${NC}"
        send_verification_code
    fi
}

# Function to install the selected script
install_script() {
    local command=$1
    echo -e "${GREEN}Running command: $command${NC}"
    eval "$command"
}

# Function to install the selected script
install_selected_script() {
    echo -e "${YELLOW}Select the script to install:${NC}"
    PS3="Enter the number corresponding to your choice: "
    select choice in "${!scripts[@]}" "cancel"; do
        if [[ -n "$choice" ]]; then
            execute_action "$choice"
            break
        else
            echo -e "${RED}Invalid choice.${NC}"
        fi
    done
}

# Function to handle invalid verification choice
invalid_choice() {
    clear_screen
    show_header
    echo -e "${RED}Invalid choice. You have $1 attempts remaining.${NC}"
}

# Function to handle invalid passcode entry
invalid_passcode() {
    clear_screen
    show_header
    echo -e "${RED}Incorrect passcode. You have $1 attempts remaining.${NC}"
}

# Main logic
show_header

attempts=2
while [[ $attempts -ge 0 ]]; do
    echo -e "${YELLOW}Choose verification method:${NC}"
    echo "1. Bot Verification"
    echo "2. IP Validation"
    echo "3. Passcode Verification"
    read -p "Enter your choice (1, 2, or 3): " verification_choice

    clear_screen
    show_header

    case $verification_choice in
        1)
            send_verification_code
            break
            ;;
        2)
            validate_ip
            break
            ;;
        3)
            passcode_attempts=2
            while [[ $passcode_attempts -ge 0 ]]; do
                read -sp "Enter passcode: " passcode
                echo
                if [[ "$passcode" == "maptech" ]]; then
                    echo -e "${GREEN}Passcode verification successful.${NC}"
                    install_selected_script
                    exit 0
                else
                    invalid_passcode $passcode_attempts
                    passcode_attempts=$((passcode_attempts - 1))
                    if [[ $passcode_attempts -lt 0 ]]; then
                        echo -e "${RED}Too many incorrect passcode attempts. Exiting.${NC}"
                        exit 1
                    fi
                fi
            done
            ;;
        *)
            invalid_choice $attempts
            attempts=$((attempts - 1))
            if [[ $attempts -lt 0 ]]; then
                echo -e "${RED}Too many invalid attempts. Exiting.${NC}"
                exit 1
            fi
            ;;
    esac
done
