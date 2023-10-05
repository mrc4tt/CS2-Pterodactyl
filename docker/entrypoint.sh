#!/bin/bash
cd /home/container
sleep 1
# Make internal Docker IP address available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

METAMOD_LATEST="https://sourcemm.net/latest.php?os=linux&version=2.0"
GAMEINFO_FIX="https://mrc4t.xyz/cs2fix.tar.gz"

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

download_patch() {
    print_bold_white "Defaulting to and downloading the latest GameInfoPatch"
    curl --location --output cs2fix.tar.gz "$GAMEINFO_FIX"
}

# Auto detect the game install path by looking for the most common game folders. Default to csgo if none are found or provided by the user.
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

# Install SourceMod/Metamod when egg variable SOURCEMOD is 1 or true. Otherwise, skip the whole step and act as normal server.
if [[ "${METAMOD}" = 1 || "${METAMOD}" == "true" ]]; then
    mkdir -p /home/container/"${INSTALL_PATH}"/tmpfiles
    cd /home/container/"${INSTALL_PATH}"/tmpfiles || exit 1

    print_yellow "MetaMod variable is set to 1 or true. Installing Metamod..."
    detect_install_path
    # Should custom versions be provided, check that they are valid. If not, use latest stable version.
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

    # Just some random shit.
    GAMEINFO_FIX="https://mrc4t.xyz/cs2fix.tar.gz"
    print_yellow "Installing GameInfo PATCH..."
    # Should custom versions be provided, check that they are valid. If not, use the latest stable version.
    if [[ -n "${GAMEINFO_VERSION}" ]]; then
        GAMEINFO_FIX="https://mrc4t.xyz/cs2fix.tar.gz"
    fi

    if [[ -z ${GAMEINFO_FIX} ]]; then
        download_patch
    else
        if is_valid_url "${GAMEINFO_FIX}"; then
                curl -JLO cs2fix.tar.gz "${GAMEINFO_FIX}"
            else          
                download_patch
            fi
    fi

    # Extract GamePatch
    print_bold_white "Extracting GAMEINFO PATCH"
    file cs2fix.tar.gz
    tar -xvzf cs2fix.tar.gz --directory /home/container/
    rm -rf "/home/container/cs2fix.tar.gz"
    print_green "GAMEINFO patch has been installed!\n"
    fi
    
# Update Source Server
if [ ! -z ${SRCDS_APPID} ]; then
    if [ ${SRCDS_STOP_UPDATE} -eq 0 ]; then
        STEAMCMD=""
        if [ ! -z ${SRCDS_BETAID} ]; then
            if [ ! -z ${SRCDS_BETAPASS} ]; then
                if [ ${SRCDS_VALIDATE} -eq 1 ]; then
                    if [ ! -z ${SRCDS_LOGIN} ]; then
                        STEAMCMD="/home/container/steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} -betapassword ${SRCDS_BETAPASS} +quit"
                    else
                        STEAMCMD="/home/container/steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} -betapassword ${SRCDS_BETAPASS} +quit"
                    fi
                else
                    if [ ! -z ${SRCDS_LOGIN} ]; then
                        STEAMCMD="/home/container/steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} -betapassword ${SRCDS_BETAPASS} +quit"
                    else
                        STEAMCMD="/home/container/steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} -betapassword ${SRCDS_BETAPASS} +quit"
                    fi
                fi
            else
                if [ ${SRCDS_VALIDATE} -eq 1 ]; then
                    if [ ! -z ${SRCDS_LOGIN} ]; then
                        STEAMCMD="/home/container/steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} +quit"
                    else             
                        STEAMCMD="/home/container/steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} +quit"
                    fi
                else
                    if [ ! -z ${SRCDS_LOGIN} ]; then
                        STEAMCMD="/home/container/steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} +quit"
                    else 
                        STEAMCMD="/home/container/steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} +quit"
                    fi
                fi
            fi
        else
            if [ ${SRCDS_VALIDATE} -eq 1 ]; then
                if [ ! -z ${SRCDS_LOGIN} ]; then
                    STEAMCMD="/home/container/steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} +quit"
                else
                    STEAMCMD="/home/container/steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} validate +quit"
                fi
            else
                if [ ! -z ${SRCDS_LOGIN} ]; then
                    STEAMCMD="/home/container/steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} +quit"
                else
                    STEAMCMD="/home/container/steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} +quit"
                fi
            fi
        fi

        # echo "SteamCMD Launch: ${STEAMCMD}"
        eval ${STEAMCMD}
    fi
fi

cd /home/container || exit 1

# Replace Startup Variables
# shellcheck disable=SC2086
MODIFIED_STARTUP=$(eval echo "$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')")

# Display the parsed startup string we're going to execute.
print_yellow "[Startup Command]: ${BOLD_WHITE} ${MODIFIED_STARTUP}\n"

# Run the Server
# shellcheck disable=SC2086
eval ${MODIFIED_STARTUP}
