#!/bin/bash
red(){ echo -e "\033[31m\033[01m$1\033[0m"; }
green(){ echo -e "\033[32m\033[01m$1\033[0m"; }
yellow(){ echo -e "\033[33m\033[01m$1\033[0m"; }
FontColor_Red="\033[31m"
FontColor_Red_Bold="\033[1;31m"
FontColor_Green="\033[32m"
FontColor_Green_Bold="\033[1;32m"
FontColor_Yellow="\033[33m"
FontColor_Yellow_Bold="\033[1;33m"
FontColor_Purple="\033[35m"
FontColor_Purple_Bold="\033[1;35m"
FontColor_Suffix="\033[0m"

log() {
    local LEVEL="$1"
    local MSG="$2"
    case "${LEVEL}" in
    INFO)
        local LEVEL="[${FontColor_Green}${LEVEL}${FontColor_Suffix}]"
        local MSG="${LEVEL} ${MSG}"
        ;;
    WARN)
        local LEVEL="[${FontColor_Yellow}${LEVEL}${FontColor_Suffix}]"
        local MSG="${LEVEL} ${MSG}"
        ;;
    ERROR)
        local LEVEL="[${FontColor_Red}${LEVEL}${FontColor_Suffix}]"
        local MSG="${LEVEL} ${MSG}"
        ;;
    *) ;;
    esac
    echo -e "${MSG}"
}

get_local_address(){
    #this fetches the IP Address of the server
    log INFO "Updating apt..."
    apt update &> /dev/null
    log INFO "Installing cURL..."
    apt install curl -y &> /dev/null
    local_ip_address=`curl ip.sb`
    install_cloudflare_warp
}

install_cloudflare_warp(){

    bash <(curl -fsSL https://cdn.n101.workers.dev/https://github.com/daycat/hax-shadowsocks-install/blob/main/warp.sh) wgd
    install_snap
}

install_snap(){
    log INFO "Now installing snap... *Elevator Music"
    apt-get install snapd -y &> /dev/null
    log INFO "Installing Snap core... "
    snap install core &> /dev/null
    install_shadowsocks
}

install_shadowsocks(){
    log INFO "Installing Shadowsocks-Libev"
    snap install shadowsocks-libev --edge &> /dev/null
    log INFO "Generating Password..."
    sspasswd=`openssl rand -base64 24`
    log INFO "Writing Config..."
    touch /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json
    cat > /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json <<-EOF
    {
    "server":["::0","0.0.0.0"],
    "server_port":8080,
    "method":"aes-256-gcm",
    "password":"$sspasswd",
    "mode":"tcp_and_udp",
    "fast_open":false
    }
EOF
    firewall_install
}

firewall_install(){
    log INFO "Configuring Firewall..."
    apt-get install ufw -y &> /dev/null
    ufw allow 8080 > /dev/null
    ufw allow ssh > /dev/null
    ufw enable
    start_ss_server
}

start_ss_server(){
    log INFO "Starting Shadowsocks-libev server..."
    systemctl start snap.shadowsocks-libev.ss-server-daemon.service
    systemctl enable snap.shadowsocks-libev.ss-server-daemon.service
    completed
}

completed(){
    green "Installation has now been completed."
    echo Your config:
    echo address:   $local_ip_address
    echo port:      8080
    echo password:  $sspasswd
    echo method:    aes-256-gcm

    green "Thanks to P3TERX for warp install script!"
    exit 0
}

get_local_address