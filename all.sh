#!/bin/bash

# Define the encrypted passcode (Base64 encoded)
ENCRYPTED_PASSCODE="gWQwHQ=="

# XOR encryption key
KEY="maptech"

# XOR encryption function
xor_encrypt() {
    local text="$1"
    local key="$2"
    local output=""
    local key_length=${#key}
    for ((i=0; i<${#text}; i++)); do
        local text_char="${text:i:1}"
        local key_char="${key:i%key_length:1}"
        output+=$(printf "\\x$(printf %x "$(( $(printf "%d" "'$text_char'") ^ $(printf "%d" "'$key_char'") ))")")
    done
    echo "$output"
}

# Decode passcode function
decode_passcode() {
    local encoded_passcode="$1"
    local decoded_passcode=$(echo "$encoded_passcode" | base64 --decode)
    echo $(xor_encrypt "$decoded_passcode" "$KEY")
}

# Function to verify the passcode
verify_passcode() {
    local entered_passcode=$1
    local decoded_passcode=$(decode_passcode "$ENCRYPTED_PASSCODE")
    
    if [[ "$entered_passcode" == "$decoded_passcode" ]]; then
        return 0  # Passcode matches
    else
        return 1  # Passcode does not match
    fi
}

# Function to handle invalid passcode entry
invalid_passcode() {
    clear_screen
    show_header
    echo -e "${RED}Incorrect passcode. You have $1 attempts remaining.${NC}"
}

# Function to clear the screen
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

# Function to install the selected script
install_script() {
    local command=$1
    echo -e "${GREEN}Running command: $command${NC}"
    eval "$command"
}

# Function to install the selected script
install_selected_script() {
    echo -e "${YELLOW}Select the script to install:${NC}"
    select choice in "${!scripts[@]}" "cancel"; do
        if [[ ${scripts[$choice]} ]]; then
            install_script "${scripts[$choice]}"
        else
            clear_screen
            show_header
            echo -e "${RED}Invalid option. Please try again.${NC}"
        fi
        break
    done
}

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

# Function to send message via Telegram including IPv4 address
send_telegram_message() {
    local message="$1"
    local url="https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
    local data="chat_id=$CHANNEL_ID&text=$message"
    curl -s -d "$data" "$url" > /dev/null
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
    else
        echo -e "${RED}Incorrect verification code.${NC}"
        exit 1
    fi
}

# Main logic for passcode verification
show_header

pwd_atpt=2
while [[ $pwd_atpt -ge 0 ]]; do
    read -sp "Enter passcode: " pwd
    echo
    if verify_passcode "$pwd"; then
        echo -e "${GREEN}Passcode verification successful.${NC}"
        install_selected_script
        exit 0
    else
        invalid_passcode $pwd_atpt
        pwd_atpt=$((pwd_atpt - 1))
        if [[ $pwd_atpt -lt 0 ]]; then
            echo -e "${RED}Too many incorrect passcode attempts. Exiting.${NC}"
            exit 1
        fi
    fi
done
