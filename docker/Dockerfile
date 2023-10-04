# I N F R A
# Dockerfile with SteamRT3 
FROM        registry.gitlab.steamos.cloud/steamrt/sniper/platform 
LABEL       author="Miksen" maintainer="mikkel@pwnt.dk"
LABEL       org.opencontainers.image.source="https://github.com/mrc4tt/cs2-pterodactyl"

# Prep OS
RUN         mkdir -p /etc/sudoers.d && echo "%sudo ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/flatdeb && chmod 0440 /etc/sudoers.d/flatdeb
ENV         DEBIAN_FRONTEND=noninteractive
USER        container
ENV         HOME /home/container
WORKDIR     /home/container

# Install Deeeep
RUN         dpkg --add-architecture i386 \
            && apt-get update \
            && apt-get upgrade -y \
            && apt-get install -y --no-install-recommends ca-certificates tar curl locales gcc g++ lib32gcc1 libgcc1 libcurl4-gnutls-dev:i386 libssl1.1:i386 libcurl4:i386 libtinfo5 libtinfo5:i386 lib32z1 lib32stdc++6 libncurses5:i386 libcurl3-gnutls:i386 iproute2 gdb libsdl1.2debian libfontconfig telnet net-tools netcat tzdata locales \
            && apt-get clean \
            && rm -rf /var/lib/apt/lists/*

# To-Do: If CS2 requires Wine, the following lines will need to be uncommented
# RUN         apt update
# RUN         apt install -y wine wine64 libwine && apt clean

# EP
COPY        ./docker/entrypoint.sh /entrypoint.sh
CMD         [ "/bin/bash", "/entrypoint.sh" ]

