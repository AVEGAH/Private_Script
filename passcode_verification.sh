#!/bin/bash

# Function to handle invalid passcode entry
invalid_passcode() {
    clear_screen
    show_header
    echo -e "${RED}Incorrect passcode. You have $1 attempts remaining.${NC}"
}

# Function to handle passcode verification
passcode_verification() {
    local passcode_attempts=2
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
}
