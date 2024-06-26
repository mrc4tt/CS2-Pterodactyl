#!/bin/bash
cd /home/container
sleep 1
# Make internal Docker IP address available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# old METAMOD_LATEST="https://sourcemm.net/latest.php?os=linux&version=2.0"
METAMOD_LATEST="https://mms.alliedmods.net/mmsdrop/2.0/mmsource-2.0.0-git1290-linux.tar.gz"

print() {
    echo -e "$1"
}

print_bold_white() {
    echo -e "\033[1;37m$1\033[0m"
}

print_yellow() {
    echo -e "\033[0;33m$1\033[0m"
}

print_red() {
    echo -e "\033[0;31m$1\033[0m"
}

print_green() {
    echo -e "\033[0;32m$1\033[0m"
}

is_valid_url() {
    local URL="$1"
    curl --output /dev/null --silent --head --fail "$URL"
    return $?
}

download_default_stable() {
    print_bold_white "Defaulting to and downloading the latest stable MetaMod 2.x releases."
    curl --location --output metamod.tar.gz "$METAMOD_LATEST"
}

INSTALL_PATH="${INSTALL_PATH:-game/csgo/}"

detect_install_path() {
    SUPPORTED_GAMES=("cs2" "csgo" "tf" "css" "dod" "cstrike" "left4dead" "leftdead2" "contagion" "alienswarm" "orangebox" "orangebox_valve" "sdk2013" "original" "darkmessiah" "bloodygoodtime" "eye" "blade" "insurgency" "pvkii" "mcv" "hl2mp" "ship")

    for i in "${SUPPORTED_GAMES[@]}"; do
        if [[ -d /home/container/"${i}" ]]; then
            INSTALL_PATH="${i}"
        fi
    done
    print_bold_white "Current detected game install folder is: ${INSTALL_PATH}"
}

# Update Server
if [[ -n ${SRCDS_APPID} ]]; then
    if [[ -n ${SRCDS_BETAID} ]]; then
        if [[ -n ${SRCDS_BETAPASS} ]]; then
            ./steamcmd/steamcmd.sh +force_install_dir /home/container +login anonymous +app_update "${SRCDS_APPID}" -beta "${SRCDS_BETAID}" -betapassword "${SRCDS_BETAPASS}" +quit
        else
            ./steamcmd/steamcmd.sh +force_install_dir /home/container +login anonymous +app_update "${SRCDS_APPID}" -beta "${SRCDS_BETAID}" +quit
        fi
    else
        ./steamcmd/steamcmd.sh +force_install_dir /home/container +login anonymous +app_update "${SRCDS_APPID}" +quit
    fi
fi

# Install SourceMod/Metamod when egg variable SOURCEMOD is 1 or true. If not, you can just skip the whole step and act like normal server.
if [[ "${METAMOD}" = 1 || "${METAMOD}" == "true" ]]; then
    mkdir -p /home/container/"${INSTALL_PATH}"/tmpfiles
    cd /home/container/"${INSTALL_PATH}"/tmpfiles || exit 1

    print_yellow "MetaMod variable is set to 1 or true. Installing Metamod..."
    detect_install_path
    # Should custom versions be provided, check that they are valid. If not, use the latest stable version.
    if [[ -n "${MM_VERSION}" ]]; then
        METAMOD_SCRAPE=$(curl https://mms.alliedmods.net/mmsdrop/${MM_VERSION}/mmsource-latest-linux -sS)
        METAMOD_URL="https://mms.alliedmods.net/mmsdrop/${MM_VERSION}/${METAMOD_SCRAPE}"
    fi

    if [[ -z ${METAMOD_URL} ]]; then
        download_default_stable
    else
        if is_valid_url "${METAMOD_URL}"; then
                curl --location --output metamod.tar.gz "${METAMOD_URL}"
            else
                print_red "The specified Metamod version: ${MM_VERSION} is not valid."
                download_default_stable
            fi
    fi
    # Extract SourceMod and Metamod
    print_bold_white "Extracting MetaMod files"
    tar -xf metamod.tar.gz --directory /home/container/"${INSTALL_PATH}"
    rm -rf "/home/container/${INSTALL_PATH}/tmpfiles"
    print_green "Metamod has been installed!\n"
fi

# Edit /home/container/game/csgo/gameinfo.gi to add MetaMod path
# Credit: https://github.com/ghostcap-gaming/ACMRS-cs2-metamod-update-fix/blob/main/acmrs.sh
GAMEINFO_FILE="/home/container/game/csgo/gameinfo.gi"
GAMEINFO_ENTRY="			Game	csgo/addons/metamod" 
if [ -f "${GAMEINFO_FILE}" ]; then
    if grep -q "Game[[:blank:]]*csgo\/addons\/metamod" "$GAMEINFO_FILE"; then # match any whitespace
        echo "File GAMEINFO.GI is already configured. No changes were made."
    else
        awk -v new_entry="$GAMEINFO_ENTRY" '
            BEGIN { found=0; }
            // {
                if (found) {
                    print new_entry;
                    found=0;
                }
                print;
            }
            /Game_LowViolence/ { found=1; }
        ' "$GAMEINFO_FILE" > "$GAMEINFO_FILE.tmp" && mv "$GAMEINFO_FILE.tmp" "$GAMEINFO_FILE"

        echo "The file ${GAMEINFO_FILE} has been configured for MetaMod successfully."
    fi
fi

cd /home/container || exit 1

# Replace Startup Variables
MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}
