#!/bin/bash

# https://stackoverflow.com/questions/3466166/how-to-check-if-running-in-cygwin-mac-or-linux
# https://stackoverflow.com/questions/17336915/return-value-in-a-bash-function
# https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html#index-FUNCNAME

function set_colors() {
    red=$(tput setaf 1)
    green=$(tput setaf 2)
    reset=$(tput sgr0)
}

function dep() {
    i=$depth
    while [ $i -gt 0 ]; do
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
        supported=no

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
    echo -e "| Ubuntu           | ${red}16.04${reset} \u274c | ${green}18.04${reset} \u2705 | ${green}20.04${reset}    | ${red}22.04${reset}    |"
    echo -e "| CentOS           | ${red}4${reset}        | ${red}5${reset}        | ${red}6${reset}        | ${red}7${reset}        |"
    echo -e "| WSL              | ${red}1${reset}        | ${red}2${reset}        |          |          |"
    echo -e "|                  |          |          |          |          |"
    echo -e "+------------------+----------+----------+----------+----------+"

    footer
}

function xema_capable_operating_environment() {
    header

    log "-> detect_host"
    detect_host
    if [[ ! $kernel = *Linux* ]]; then
        echo "${red}$kernel Environment is not supported.${reset}"
    else
        log "-> detect_distro"
        detect_distro
        # detect_distro also calls version detection
        if [[ ! $distro = *Ubuntu* ]]; then
            echo "${red}$distro Linux Distribution is not supported.${reset}"
        else
            log "-> check_supported_matrix"
            check_supported_matrix

            if [[ $installable == "yes" && $supported == "no" ]]; then
                log "-> print_support_matrix"
                print_support_matrix
                echo "${red}Unsupported configuration.${reset} $hostsys $kernel $distro $oever"
                echo "${red}!!! Install at your own risk !!! ${reset}"
            elif [[ $installable == "no" ]]; then
                echo "${red}!!! Unable to install !!! ${reset}"
                echo "${red}Unsupported configuration.${reset} $hostsys $kernel $distro $oever"
            fi

            if [[ $installable == "yes" ]]; then
                # echo "${green}"
                echo -e "OS:      " $distro
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

    which asterisk
    if [ "$?" -ne "0" ]; then
        apt -qqq install -y asterisk
    fi

    which mysql
    if [ "$?" -ne "0" ]; then
        apt -qqq install -y mariadb-server
    fi

    which nginx
    if [ "$?" -ne "0" ]; then
        apt -qqq install -y nginx
    fi

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
        echo "${red}$LINENO: Not implemented${reset}"
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
function intall_dependencies() {
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

function install_xema_binary() {
    header

    footer
}

# variable $installed
function install_tools_and_binaries() {
    header
    installed="no"

    log "dependency -> xema_capable_operating_environment"
    xema_capable_operating_environment

    if [[ $installable == "yes" ]]; then
        log "-> install_tools"
        echo "${green}Installing tools ...${reset}"
        install_tools

        log "-> intall_dependencies"
        echo "${green}Installing dependencies ...${reset}"
        intall_dependencies

        log "-> install_xema_binary"
        echo "${green}Installing Xema Manager ...${reset}"
        install_xema_binary

        installed="yes"
    fi

    footer installed="$installed"
}

function configure_firewall() {
    header

    footer
}

function configure_nginx() {
    header

    footer
}

function configure_asterisk() {
    header

    footer
}

function configure_mysql() {
    header

    footer
}

function configure_logrotate() {
    header

    footer
}

function configure_xema_service() {
    header

    footer
}

function configure_admin_access() {
    header

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

function bootstrap() {
    header
    success="no"

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

# finally
depth=0
set_colors
bootstrap
if [[ $success == "no" ]]; then show_log; fi
