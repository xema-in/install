#!/bin/bash

# https://stackoverflow.com/questions/3466166/how-to-check-if-running-in-cygwin-mac-or-linux
# https://stackoverflow.com/questions/17336915/return-value-in-a-bash-function
# https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html#index-FUNCNAME
# https://www.redhat.com/sysadmin/arguments-options-bash-scripts

function set_colors() {
    red=$(tput setaf 1)
    green=$(tput setaf 2)
    reset=$(tput sgr0)
}

function dep() {
    i=$depth
    while [[ $i -gt 0 ]]; do
        echo -n "  "
        let "i-=1"
    done
    echo -n ""
}

function lineno1() {
    lineno="...........1."${BASH_LINENO[1]}
    echo -n ${lineno:(-5)}
}

function lineno2() {
    # space is not working, so, using . to pad
    lineno="...........2."${BASH_LINENO[2]}
    echo -n ${lineno:(-5)}
}

function lineno3() {
    lineno="...........3."${BASH_LINENO[3]}
    echo -n ${lineno:(-5)}
}

function header() {
    logger+=$(lineno1)".H.: "$(dep)${FUNCNAME[1]}$'()\n'
    let "depth++"
}

function footer() {
    let "depth--"
    logger+=$(lineno1)".F.: "$(dep)${FUNCNAME[1]}"() completed. "$1$'\n'
}

log() {
    logger+=$(lineno1)".L.: "$(dep)$1$'\n'
    # echo "DEBUG: $1"
}

# variable: $hostsys $kernel
function detect_host() {
    header

    unameOut="$(uname -sro)"
    log "uname -sro: ""${green}$unameOut${reset}"

    case "${unameOut}" in
    Darwin*) hostsys="Mac" ;;
    Linux*Microsoft* | Linux*microsoft*) hostsys="WSL" ;;
    Linux*) hostsys="Linux" ;;
    CYGWIN* | MINGW*) hostsys="Windows" ;;
    *) hostsys="Unknown" ;;
    esac

    case "${unameOut}" in
    Darwin*) kernel="OS X" ;;
    Linux*) kernel="Linux" ;;
    CYGWIN* | MINGW*) kernel="Windows" ;;
    *) kernel="Unknown" ;;
    esac

    footer hostsys="$hostsys",kernel="$kernel"
}

# variable $oever
function detect_ubuntu_version() {
    header

    lsbOut="$(lsb_release -rs)"
    log "lsb_release -rs: ""${green}$lsbOut${reset}"

    case "${lsbOut}" in
    18.*) oever="18" ;;
    20.*) oever="20" ;;
    22.*) oever="22" ;;
    # 24.*) oever="24" ;;
    *) oever="Unknown" ;;
    esac

    footer oever="$oever"
}

# variable $oever
function detect_centos_version() {
    header

    log "${red}Not implemented${reset}"

    footer
}

# variable $distro
function detect_distro() {
    header

    if [[ $(lsb_release -is) = *Ubuntu* ]]; then
        log "lsb_release -is: "${green}$(lsb_release -is)${reset}
        distro="Ubuntu"
        detect_ubuntu_version
    elif [[ $(cat /etc/os-release | grep "^NAME=") = *CentOS* ]]; then
        distro="CentOS"
        detect_centos_version
    else
        distro="Unknown"
    fi

    footer distro="$distro"
}

# variable supported, installable
function check_supported_matrix() {
    header
    supported="no"
    installable="no"

    log "${red}$hostsys $kernel $distro $oever${reset}"

    # linux kernel running ubuntu
    if [[ $hostsys == "Linux" && $kernel == "Linux" && $distro == "Ubuntu" && $oever == "16" ]]; then
        installable=yes
        supported=no
    elif [[ $hostsys == "Linux" && $kernel == "Linux" && $distro == "Ubuntu" && $oever == "18" ]]; then
        installable=yes
        supported=yes
    elif [[ $hostsys == "Linux" && $kernel == "Linux" && $distro == "Ubuntu" && $oever == "20" ]]; then
        installable=yes
        supported=no
    elif [[ $hostsys == "Linux" && $kernel == "Linux" && $distro == "Ubuntu" && $oever == "22" ]]; then
        installable=yes
        supported=yes

    # wsl running ubuntu
    elif [[ $hostsys == "WSL" && $kernel == "Linux" && $distro == "Ubuntu" && $oever == "18" ]]; then
        installable=no
        supported=no
    elif [[ $hostsys == "WSL" && $kernel == "Linux" && $distro == "Ubuntu" && $oever == "20" ]]; then
        installable=no
        supported=no
    elif [[ $hostsys == "WSL" && $kernel == "Linux" && $distro == "Ubuntu" && $oever == "22" ]]; then
        installable=no
        supported=no

    # other
    elif [[ $distro == "Unknown" && $oever == "2" ]]; then
        installable=no
        supported=no
    fi

    footer installable="$installable",supported="$supported"
}

function print_support_matrix() {
    header

    echo -e "+------------------+----------+----------+----------+----------+"
    echo -e "| Distro           | Ver. 1   | Ver. 2   | Ver. 3   | Ver. 4   |"
    echo -e "+------------------+----------+----------+----------+----------+"
    echo -e "| Ubuntu           | ${red}16.04${reset} \u274c | ${green}18.04${reset} \u2705 | ${green}20.04${reset}    | ${green}22.04${reset} \u2705 |"
    echo -e "| CentOS           | ${red}4${reset}        | ${red}5${reset}        | ${red}6${reset}        | ${red}7${reset}        |"
    #    echo -e "| WSL              | ${red}1${reset}        | ${red}2${reset}        |          |          |"
    echo -e "|                  |          |          |          |          |"
    echo -e "+------------------+----------+----------+----------+----------+"

    footer
}

function xema_capable_operating_environment() {
    header

    log "dependency -> detect_host"
    detect_host
    if [[ ! $kernel = *Linux* ]]; then
        echo "${red}$kernel Environment is not supported.${reset}"
    else
        log "dependency -> detect_distro and version"
        detect_distro
        # detect_distro also calls version detection
        if [[ ! $distro = *Ubuntu* ]]; then
            echo "${red}$distro Linux Distribution is not supported.${reset}"
        else
            log "dependency -> check_supported_matrix"
            check_supported_matrix

            if [[ $installable == "yes" && $supported == "no" ]]; then
                log "dependency -> print_support_matrix"
                print_support_matrix
                echo "${red}Unsupported configuration.${reset} $hostsys $kernel $distro $oever"
                echo "${red}!!! Install at your own risk !!! ${reset}"
            elif [[ $installable == "no" ]]; then
                echo "${red}!!! Unable to install !!! ${reset}"
                echo "${red}Unsupported configuration.${reset} $hostsys $kernel $distro $oever"
            fi

            if [[ $installable == "yes" ]]; then
                # echo "${green}"
                echo -e "Distro:  " $distro
                echo -e "Version: " $oever
                if [[ $supported == "yes" ]]; then echo -e "Support:  \u2705"; fi
                if [[ $supported == "no" ]]; then echo -e "Support:  \u274c"; fi
                # echo "${reset}"
            fi
        fi
    fi

    footer
}

# tools
function install_tools() {
    header

    if [ "$distro" == "Ubuntu" ]; then
        apt -qqq update
        apt -qqq install -y curl wget unzip at git
    fi

    if [ "$distro" == "CentOS" ]; then
        echo "${red}$LINENO: Not implemented${reset}"
    fi

    if [ "$distro" == "Unknown" ]; then
        echo "${red}$LINENO: $distro OS${reset}"
    fi

    footer
}

# ubuntu dependencies
function ubuntu_dependencies() {
    header

    which asterisk >/dev/null
    if [ "$?" -ne "0" ]; then
        apt -qqq install -y asterisk
    fi

    which nginx >/dev/null
    if [ "$?" -ne "0" ]; then
        apt -qqq install -y nginx
    fi

    install_mariadb="no"

    which mysql >/dev/null
    if [ "$?" -ne "0" ]; then
        # apt -qqq install -y mariadb-server
        install_mariadb="yes"
    fi

    mysql -e "show databases"
    if [ "$?" -ne "0" ]; then
        install_mariadb="yes"
    fi

    if [ "$install_mariadb" == "yes" ]; then
        apt -qqq install -y mariadb-server
    fi

    # ensure services are running
    systemctl start asterisk
    systemctl start nginx
    systemctl start mariadb

    footer
}

# ubuntu dotnet
function ubuntu_dotnet() {
    header

    if [ "$oever" == "18" ]; then
        wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
        dpkg -i /tmp/packages-microsoft-prod.deb
        add-apt-repository universe
    elif [ "$oever" == "20" ]; then
        echo "${red}$LINENO: Not implemented${reset}"
    elif [ "$oever" == "22" ]; then
        apt -qqq install aspnetcore-runtime-8.0
    else
        echo "${red}$LINENO: Not implemented${reset}"
    fi

    footer
}

# centos dependencies
function centos_dependencies() {
    header

    echo "${red}$LINENO: Not implemented${reset}"

    footer
}

# centos dotnet
function centos_dotnet() {
    header

    echo "${red}$LINENO: Not implemented${reset}"

    footer
}

# asterisk
function install_dependencies() {
    header

    if [ "$distro" == "Ubuntu" ]; then
        ubuntu_dependencies
        ubuntu_dotnet
    fi

    if [ "$distro" == "CentOS" ]; then
        centos_dependencies
        centos_dotnet
    fi

    if [ "$distro" == "Unknown" ]; then
        echo "${red}$LINENO: $distro OS${reset}"
    fi

    footer
}

# https://github.com/xema-in/manager/releases/download/dev/Manager.zip
function install_xema_dev_channel() {
    header

    echo "Installing from ${green}$channel${reset} channel ..."

    if [ "$distro" == "Ubuntu" ]; then
        wget -c https://github.com/xema-in/manager/releases/download/dev/Manager.zip -O /tmp/manager.zip
        unzip -o /tmp/manager.zip -d /var/lib/xema/manager
    fi

    if [ "$distro" == "CentOS" ]; then
        echo "${red}$LINENO: Not implemented${reset}"
    fi

    if [ "$distro" == "Unknown" ]; then
        echo "${red}$LINENO: $distro OS${reset}"
    fi

    footer
}

# https://github.com/xema-in/manager/releases/download/v2.0/Manager.zip
function install_xema_prod_channel() {
    header

    echo "Installing from ${green}$channel${reset} channel ..."

    if [ "$distro" == "Ubuntu" ]; then
        wget -c https://github.com/xema-in/manager/releases/download/v2.0/Manager.zip -O /tmp/manager.zip
        unzip -o /tmp/manager.zip -d /var/lib/xema/manager
    fi

    if [ "$distro" == "CentOS" ]; then
        echo "${red}$LINENO: Not implemented${reset}"
    fi

    if [ "$distro" == "Unknown" ]; then
        echo "${red}$LINENO: $distro OS${reset}"
    fi

    footer
}

function backup_existing_installation() {
    header

    mkdir -p /var/lib/xema/manager
    cp -r /var/lib/xema/manager /var/lib/xema/manager.$(date '+%Y%m%d.%H')
    rm -rf /tmp/manager.zip

    footer
}

function add_default_settings() {
    header

    cp -n /var/lib/xema/manager/appsettings.default.json /var/lib/xema/manager/appsettings.json

    footer
}

function install_xema_binary() {
    header

    backup_existing_installation

    if [ "$channel" == "release" ]; then
        log "dependency -> install_xema_prod_channel"
        install_xema_prod_channel
    fi

    if [ "$channel" == "dev" ]; then
        log "dependency -> install_xema_dev_channel"
        install_xema_dev_channel
    fi

    add_default_settings

    footer
}

# variable $installed
function install_tools_and_binaries() {
    header
    installed="no"

    log "dependency -> xema_capable_operating_environment"
    xema_capable_operating_environment

    if [[ $installable == "yes" ]]; then
        log "dependency -> install_tools"
        echo "${green}Installing tools ...${reset}"
        install_tools

        log "dependency -> install_dependencies"
        echo "${green}Installing dependencies ...${reset}"
        install_dependencies

        log "dependency -> install_xema_binary"
        echo "${green}Installing Xema Manager ...${reset}"
        install_xema_binary

        installed="yes"
    fi

    footer installed="$installed"
}

function configure_firewall() {
    header

    # Ubuntu: ufw
    # CentOS: firewalld

    if [ "$distro" == "Ubuntu" ]; then
        ufw disable
    fi

    if [ "$distro" == "CentOS" ]; then
        systemctl stop firewalld
        systemctl disable firewalld
        systemctl mask --now firewalld
    fi

    if [ "$distro" == "Unknown" ]; then
        echo "${red}$LINENO: $distro OS${reset}"
    fi

    footer
}

function generate_self_signed_ssl() {
    header

    if [ "$distro" == "Ubuntu" ]; then

        ls /etc/ssl/private/key.pem
        if [ "$?" -ne "0" ]; then
            openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/private/key.pem -out /etc/ssl/certs/certificate.pem -subj "/CN=xema-manager"
        fi

    fi

    if [ "$distro" == "CentOS" ]; then
        echo "${red}$LINENO: Not implemented${reset}"
    fi

    if [ "$distro" == "Unknown" ]; then
        echo "${red}$LINENO: $distro OS${reset}"
    fi

    footer
}

function configure_nginx() {
    header

    generate_self_signed_ssl

    if [ "$distro" == "Ubuntu" ]; then

        wget -q https://raw.githubusercontent.com/xema-in/install/master/deps/xema.nginx -O /tmp/xema.nginx
        cp /tmp/xema.nginx /etc/nginx/sites-available/xema.nginx

        ls /etc/nginx/sites-enabled/xema.nginx
        if [ "$?" -ne "0" ]; then
            ln -s /etc/nginx/sites-available/xema.nginx /etc/nginx/sites-enabled/xema.nginx
        fi

        ls /etc/nginx/sites-enabled/default
        if [ "$?" -eq "0" ]; then
            rm /etc/nginx/sites-enabled/default
        fi

        nginx -s reload

    fi

    if [ "$distro" == "CentOS" ]; then

        wget -q https://raw.githubusercontent.com/xema-in/install/master/deps/xema.nginx -O /tmp/xema.nginx
        cp /tmp/xema.nginx /etc/nginx/conf.d/xema.conf

        nginx -s reload

    fi

    if [ "$distro" == "Unknown" ]; then
        echo "${red}$LINENO: $distro OS${reset}"
    fi

    footer
}

function configure_asterisk() {
    header

    # if [ "$distro" == "Ubuntu" ]; then
    #     echo "${red}$LINENO: Not implemented${reset}"
    # fi

    if [ "$distro" == "CentOS" ]; then
        echo "${red}$LINENO: Not implemented${reset}"
    fi

    if [ "$distro" == "Unknown" ]; then
        echo "${red}$LINENO: $distro OS${reset}"
    fi

    footer
}

function configure_mysql() {
    header

    mysql -u root -e "CREATE USER IF NOT EXISTS 'xema'@'localhost' IDENTIFIED BY 'xema';GRANT ALL PRIVILEGES ON *.* TO 'xema'@'localhost';FLUSH PRIVILEGES;"

    # if [ "$distro" == "Ubuntu" ]; then
    #     echo "${red}$LINENO: Not implemented${reset}"
    # fi

    # if [ "$distro" == "CentOS" ]; then
    #     echo "${red}$LINENO: Not implemented${reset}"
    # fi

    # if [ "$distro" == "Unknown" ]; then
    #     echo "${red}$LINENO: $distro OS${reset}"
    # fi

    footer
}

function configure_logrotate() {
    header

    if [ "$distro" == "Ubuntu" ]; then
        wget -q https://raw.githubusercontent.com/xema-in/install/master/deps/asterisk-master-csv -O /tmp/asterisk-master-csv
        cp /tmp/asterisk-master-csv /etc/logrotate.d/asterisk-master-csv
    fi

    if [ "$distro" == "CentOS" ]; then
        echo "${red}$LINENO: Not implemented${reset}"
    fi

    if [ "$distro" == "Unknown" ]; then
        echo "${red}$LINENO: $distro OS${reset}"
    fi

    footer
}

function configure_xema_service() {
    header

    # if [[ $hostsys == "Linux" && $kernel == "Linux" && $distro == "Ubuntu" && $oever == "16" ]]; then
    #     installable=yes
    #     supported=no
    # elif [[ $hostsys == "Linux" && $kernel == "Linux" && $distro == "Ubuntu" && $oever == "18" ]]; then
    #     installable=yes
    #     supported=yes
    # elif [[ $hostsys == "Linux" && $kernel == "Linux" && $distro == "Ubuntu" && $oever == "20" ]]; then
    #     installable=yes
    #     supported=no
    # elif [[ $hostsys == "Linux" && $kernel == "Linux" && $distro == "Ubuntu" && $oever == "22" ]]; then
    #     installable=yes
    #     supported=no

    # elif [[ $hostsys == "WSL" && $kernel == "Linux" && $distro == "Ubuntu" && $oever == "20" ]]; then
    #     installable=no
    #     supported=no
    # elif [[ $hostsys == "WSL" && $kernel == "Linux" && $distro == "Ubuntu" && $oever == "22" ]]; then
    #     installable=yes
    #     supported=no

    # # other
    # elif [[ $distro == "Unknown" && $oever == "2" ]]; then
    #     installable=no
    #     supported=no
    # fi

    if [[ $hostsys == "WSL" && $kernel == "Linux" ]]; then
        # wsl
        ls /etc/init.d/xema-manager
        if [ "$?" -ne "0" ]; then
            wget -q https://raw.githubusercontent.com/xema-in/install/master/deps/xema-manager -O /tmp/xema-manager
            cp /tmp/xema-manager /etc/init.d/xema-manager
            chmod +x /etc/init.d/xema-manager
            update-rc.d xema-manager defaults
        fi

    elif [[ $hostsys == "Linux" && $kernel == "Linux" ]]; then
        # Ubuntu, CentOS

        ls /etc/systemd/system/multi-user.target.wants/xema-manager.service
        if [ "$?" -ne "0" ]; then
            wget -q https://raw.githubusercontent.com/xema-in/install/master/deps/xema-manager.service -O /tmp/xema-manager.service
            cp /tmp/xema-manager.service /lib/systemd/system/xema-manager.service
            ln -s /lib/systemd/system/xema-manager.service /etc/systemd/system/multi-user.target.wants/xema-manager.service
            systemctl daemon-reload
            systemctl enable xema-manager.service
        fi

    fi

    # if [ "$distro" == "Ubuntu" ]; then
    #     echo "${red}$LINENO: Not implemented${reset}"
    # fi

    # if [ "$distro" == "CentOS" ]; then
    #     echo "${red}$LINENO: Not implemented${reset}"
    # fi

    # if [ "$distro" == "Unknown" ]; then
    #     echo "${red}$LINENO: $distro OS${reset}"
    # fi

    footer
}

function configure_admin_access() {
    header

    if [ "$distro" == "Ubuntu" ]; then
        ssh-import-id-gh VasuInukollu
    fi

    if [ "$distro" == "CentOS" ]; then
        echo "${red}$LINENO: Not implemented${reset}"
    fi

    if [ "$distro" == "Unknown" ]; then
        echo "${red}$LINENO: $distro OS${reset}"
    fi

    footer
}

# variable $configured
function install_and_configure_system() {
    header
    configured="no"

    log "dependency -> install_tools_and_binaries"
    install_tools_and_binaries

    if [[ $installed == "yes" ]]; then

        log "-> configure_firewall"
        configure_firewall

        log "-> configure_nginx"
        configure_nginx

        log "-> configure_asterisk"
        configure_asterisk

        log "-> configure_mysql"
        configure_mysql

        log "-> configure_logrotate"
        configure_logrotate

        log "-> configure_xema_service"
        configure_xema_service

        log "-> configure_admin_access"
        configure_admin_access

        configured="yes"
    fi

    footer configured="$configured"
}

function setup_and_start_services() {
    header
    started="no"

    log "dependency -> install_and_configure_system"
    install_and_configure_system

    if [[ $configured == "yes" ]]; then

        log "-> service xema-manager start"
        service xema-manager start

        started="yes"
    fi

    footer started="$started"
}

help() {
    # Display Help
    echo "Install Xema Platform software."
    echo "Syntax: ./install-xema.sh [-d|h]"
    echo "options:"
    echo "h     Print this Help."
    echo "d     Install the Dev release."
    echo
}

function bootstrap() {
    header
    success="no"

    echo "Selected ${green}$channel${reset} channel ..."

    log "dependency -> setup_and_start_services"
    setup_and_start_services

    if [[ $started == "yes" ]]; then

        # do anything else neededd

        success="yes"
    fi

    footer success="$success"
}

function show_log() {
    # "" required to display new lines
    echo "$logger"
}

function detect_installed_channel() {
    header

    if [[ -f /var/lib/xema/manager/appsettings.json ]]; then
        channel=$(cat /var/lib/xema/manager/appsettings.json | grep '"Channel":' | cut -d'"' -f4)
    fi

    footer channel="$channel"
}

# finally
channel="release"
while getopts hd option; do
    case $option in
    h) # display Help
        help
        exit
        ;;
    d) # Dev release
        channel="dev"
        ;;
    \?) # Invalid option
        echo "Error: Invalid option"
        echo
        Help
        exit
        ;;
    esac
done

#detect_installed_channel

log "channel: ""${green}$channel${reset}"

depth=0
set_colors
bootstrap
if [[ $success == "no" ]]; then show_log; fi
