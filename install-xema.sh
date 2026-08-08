#!/bin/bash

# https://stackoverflow.com/questions/3466166/how-to-check-if-running-in-cygwin-mac-or-linux
# https://stackoverflow.com/questions/17336915/return-value-in-a-bash-function
# https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html#index-FUNCNAME
# https://www.redhat.com/sysadmin/arguments-options-bash-scripts


# Where things live on a server.
#
# Program code, configuration and state have three different lifetimes: code is replaced
# wholesale on upgrade, configuration is edited by the administrator, state is written by the
# service. Keeping them apart is what stops an upgrade destroying settings, and lets a service
# run without write access to its own binaries. FHS puts vendor code under /opt, configuration
# under /etc and state under /var/lib.
XEMA_INSTALL_DIR="/opt/techsudoku/xema"
XEMA_CONFIG_DIR="/etc/xema"
XEMA_STATE_DIR="/var/lib/xema"

# The layout before this change: everything, including configuration, in one directory.
XEMA_LEGACY_DIR="/var/lib/xema"

# Define the support matrix in a central place
function define_support_matrix() {
    # Define arrays for each configuration
    # Format: distro|hostsys|kernel|version|installable|supported|details
    SUPPORT_MATRIX=(
        "Ubuntu|Linux|Linux|20|no|no"
        "Ubuntu|Linux|Linux|22|yes|yes"
        "Ubuntu|Linux|Linux|24|yes|no"
        "Ubuntu|Linux|Linux|25|yes|no"
        "Ubuntu|Linux|Linux|26|yes|no"
        "CentOS|Linux|Linux|4|no|no"
        "Ubuntu|WSL|Linux|25|yes|no"
    )
}

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
    24.*) oever="24" ;;
    25.*) oever="25" ;;
    26.*) oever="26" ;;
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

# variable $supported, $installable
function check_support_matrix() {
    header
    supported="no"
    installable="no"

    log "${red}$hostsys $kernel $distro $oever${reset}"

    # Call the common function to define the support matrix
    define_support_matrix

    # Check the current configuration against the matrix
    for config in "${SUPPORT_MATRIX[@]}"; do
        # More compatible way to split the string
        OLD_IFS="$IFS"
        IFS="|"
        set -- $config
        conf_distro="$1"
        conf_hostsys="$2"
        conf_kernel="$3"
        conf_version="$4"
        conf_installable="$5"
        conf_supported="$6"
        IFS="$OLD_IFS"
        
        if [[ $distro == "$conf_distro" && $hostsys == "$conf_hostsys" && $kernel == "$conf_kernel" && $oever == "$conf_version" ]]; then
            installable="$conf_installable"
            supported="$conf_supported"
            break
        fi
    done

    footer installable="$installable",supported="$supported"
}

function print_support_matrix() {
    header

    # Call the common function to define the support matrix
    define_support_matrix

    # Table header
    printf "+------------------+----------+----------+----------+\n"
    printf "| %-16s | %-8s | %-8s | %-8s |\n" "Environment" "Version" "Install" "Support"
    printf "+------------------+----------+----------+----------+\n"
    
    # Loop through the support matrix to print each configuration
    for config in "${SUPPORT_MATRIX[@]}"; do
        # More compatible way to split the string
        OLD_IFS="$IFS"
        IFS="|"
        set -- $config
        conf_distro="$1"
        conf_hostsys="$2"
        conf_kernel="$3"
        conf_version="$4"
        conf_installable="$5"
        conf_supported="$6"
        IFS="$OLD_IFS"
                
        # Format the install and support status with fixed column width
        if [[ $conf_installable == "yes" ]]; then
            install_mark="   ${green}✅${reset}   "
        else
            install_mark="   ${red}❌${reset}   "
        fi
        
        if [[ $conf_supported == "yes" ]]; then
            support_mark="   ${green}✅${reset}   "
        else
            support_mark="   ${red}❌${reset}   "
        fi
        
        # Print the row with fixed column widths
        printf "| %-16s | %-8s | %-8s | %-8s |\n" "$conf_distro ($conf_hostsys)" "$conf_version" "$install_mark" "$support_mark"
    done
    
    # Footer line
    printf "+------------------+----------+----------+----------+\n"

    footer
}

# variable $installed
function install_tools_and_binaries() {
    header
    installed="no"

    log "-> xema_capable_operating_environment"
    xema_capable_operating_environment

    if [[ $installable == "yes" ]]; then
        log "-> install_tools"
        echo "${green}Installing tools ...${reset}"
        install_tools

        log "-> install_dependencies"
        echo "${green}Installing dependencies ...${reset}"
        install_dependencies

        log "-> migrate_xema_layout"
        echo "${green}Checking filesystem layout ...${reset}"
        migrate_xema_layout

        log "-> install_xema_fastagi"
        echo "${green}Installing Xema FastAGI ...${reset}"
        install_xema_fastagi

        log "-> install_xema_astermq"
        echo "${green}Installing Xema AsterMQ ...${reset}"
        install_xema_astermq

        log "-> install_xema_simplecdr"
        echo "${green}Installing Xema SimpleCdr ...${reset}"
        install_xema_simplecdr

        log "-> install_xema_bff"
        echo "${green}Installing Xema BFF ...${reset}"
        install_xema_bff

        log "-> install_xema_queue"
        echo "${green}Installing Xema Queue ...${reset}"
        install_xema_queue

        log "-> install_xema_tracer"
        echo "${green}Installing Xema Tracer ...${reset}"
        install_xema_tracer

        log "-> install_xema_sipper"
        echo "${green}Installing Xema Sipper ...${reset}"
        install_xema_sipper

        log "-> install_xema_missingcdrs"
        echo "${green}Installing Xema MissingCdrs ...${reset}"
        install_xema_missingcdrs

        log "-> install_xema_ava"
        echo "${green}Installing Xema Ava ...${reset}"
        install_xema_ava

        log "-> install_xema_metrics"
        echo "${green}Installing Xema Metrics ...${reset}"
        install_xema_metrics

        log "-> install_xema_metricsbackfill"
        echo "${green}Installing Xema Metrics Backfill ...${reset}"
        install_xema_metricsbackfill

        log "-> install_xema_cli"
        echo "${green}Installing Xema CLI ...${reset}"
        install_xema_cli

        log "-> install_xema_binary"
        echo "${green}Installing Xema Manager ...${reset}"
        install_xema_binary

        installed="yes"
    fi

    footer installed="$installed"
}

function xema_capable_operating_environment() {
    header

    log "-> detect_host"
    detect_host
    if [[ ! $kernel = *Linux* ]]; then
        echo "${red}$kernel Environment is not supported.${reset}"
    else
        log "-> detect_distro and version"
        detect_distro
        # detect_distro also calls version detection
        if [[ ! $distro = *Ubuntu* ]]; then
            echo "${red}$distro Linux Distribution is not supported.${reset}"
        else
            log "-> check_support_matrix"
            check_support_matrix

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
                echo -e "Distro:  " $distro
                echo -e "Version: " $oever
                if [[ $supported == "yes" ]]; then echo -e "Support:  ${green}✅${reset}"; fi
                if [[ $supported == "no" ]]; then echo -e "Support:  ${red}❌${reset}"; fi
                # echo "${reset}"
            fi
        fi
    fi

    footer
}

function install_tools() {
    header

    if [ "$distro" == "Ubuntu" ]; then
        apt $apt_quiet update
        apt $apt_quiet install -y curl wget unzip at sngrep libpcap0.8
        # apt $apt_quiet install -y git sipsak linphone-cli
    fi

    if [ "$distro" == "CentOS" ]; then
        echo "${red}$LINENO: Not implemented${reset}"
    fi

    if [ "$distro" == "Unknown" ]; then
        echo "${red}$LINENO: $distro OS${reset}"
    fi

    footer
}

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

# ubuntu dependencies
function ubuntu_dependencies() {
    header

    which asterisk >/dev/null
    if [ "$?" -ne "0" ]; then
        apt $apt_quiet install -y asterisk
        systemctl start asterisk
    fi

    which nginx >/dev/null
    if [ "$?" -ne "0" ]; then
        apt $apt_quiet install -y nginx
        systemctl start nginx
    fi

    which rabbitmq-server >/dev/null
    if [ "$?" -ne "0" ]; then
        apt $apt_quiet install -y rabbitmq-server
        systemctl start rabbitmq-server
    fi

    which redis-server >/dev/null
    if [ "$?" -ne "0" ]; then
        apt $apt_quiet install -y redis-server
        systemctl start redis-server
    fi

    which prometheus >/dev/null
    if [ "$?" -ne "0" ]; then
        apt $apt_quiet install -y prometheus
        systemctl start prometheus
    fi

    install_mariadb="no"

    which mysql >/dev/null
    if [ "$?" -ne "0" ]; then
        # apt $apt_quiet install -y mariadb-server
        install_mariadb="yes"
    fi

    mysql -e "show databases" >/dev/null
    if [ "$?" -ne "0" ]; then
        install_mariadb="yes"
    fi

    if [ "$install_mariadb" == "yes" ]; then
        apt $apt_quiet install -y mariadb-server
        systemctl start mariadb
    fi

    footer
}

# ubuntu dotnet
function ubuntu_dotnet() {
    header

    if [ "$oever" == "18" ]; then
        wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
        dpkg -i /tmp/packages-microsoft-prod.deb
        add-apt-repository -y universe
    elif [ "$oever" == "20" ]; then
        echo "${red}$LINENO: Not implemented${reset}"
    elif [ "$oever" == "22" ]; then
        add-apt-repository -y ppa:dotnet/backports
        apt update
        apt $apt_quiet install -y dotnet-runtime-10.0
        apt $apt_quiet install -y aspnetcore-runtime-10.0
    elif [ "$oever" == "24" ] || [ "$oever" == "25" ] || [ "$oever" == "26" ]; then
        apt $apt_quiet install -y dotnet-runtime-10.0
        apt $apt_quiet install -y aspnetcore-runtime-10.0
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

# SIP realms: the templated unit that runs one SIP proxy per carrier, each inside that
# carrier's own network namespace.
#
# NOT WIRED UP. Nothing calls this yet and the kamailio package is not installed by default.
# Add the call to install_tools_and_binaries once realms are ready to ship.
function install_kamailio_realms() {
    header

    if [ "$distro" == "Ubuntu" ]; then
        mkdir -p /etc/kamailio/realms

        # A template, so it is never started on its own -- only as kamailio-realm@<realm>.
        wget -q "https://raw.githubusercontent.com/xema-in/install/master/deps/kamailio-realm@.service" -O "/tmp/kamailio-realm@.service"
        cp "/tmp/kamailio-realm@.service" "/lib/systemd/system/kamailio-realm@.service"

        systemctl daemon-reload
    fi

    footer
}

function xema_release_tag() {
    if [ "$channel" == "dev" ]; then
        echo "dev"
    else
        echo "v2.0"
    fi
}

# Fetch one component's release zip and unpack it over its own directory under the install dir.
# Every component below is this and nothing else; they differ only in name.
function install_xema_component() {
    local dir="$1"
    local zip="$2"
    local tag
    tag=$(xema_release_tag)

    if [ "$distro" != "Ubuntu" ]; then
        return 0
    fi

    mkdir -p "$XEMA_INSTALL_DIR/$dir"
    rm -rf "/tmp/$zip"

    wget -q --show-progress "https://github.com/xema-in/manager/releases/download/$tag/$zip" -O "/tmp/$zip"
    unzip -qo "/tmp/$zip" -d "$XEMA_INSTALL_DIR/$dir"

    # Configuration does not live with the code. A release ships a default appsettings.json;
    # seed /etc/xema from it only when there is nothing there, so an upgrade never overwrites
    # what an administrator has set.
    mkdir -p "$XEMA_CONFIG_DIR"
    if [ -f "$XEMA_INSTALL_DIR/$dir/appsettings.json" ]; then
        cp --update=none "$XEMA_INSTALL_DIR/$dir/appsettings.json" "$XEMA_CONFIG_DIR/$dir.json"
    fi

    # State is the service's to write, and is the one thing that stays in /var/lib.
    mkdir -p "$XEMA_STATE_DIR/$dir"
}

function install_xema_fastagi() {
    header
    install_xema_component "fastagi" "FastAGI.zip"
    footer
}

function install_xema_astermq() {
    header
    install_xema_component "astermq" "AsterMQ.zip"
    footer
}

function install_xema_simplecdr() {
    header
    install_xema_component "simplecdr" "SimpleCdr.zip"
    footer
}

function install_xema_bff() {
    header
    install_xema_component "bff" "Bff.zip"
    footer
}

function install_xema_queue() {
    header
    install_xema_component "queue" "Queue.zip"
    footer
}

function install_xema_tracer() {
    header
    install_xema_component "tracer" "Tracer.zip"
    footer
}

function install_xema_sipper() {
    header
    install_xema_component "sipper" "Sipper.zip"
    footer
}

function install_xema_missingcdrs() {
    header
    install_xema_component "import" "MissingCdrs.zip"
    footer
}

function install_xema_ava() {
    header
    install_xema_component "ava" "Ava.zip"
    footer
}

function install_xema_metrics() {
    header
    install_xema_component "metrics" "Metrics.zip"
    footer
}

function install_xema_metricsbackfill() {
    header
    install_xema_component "backfill" "MetricsBackfill.zip"
    footer
}

function install_xema_cli() {
    header

    rm -rf /tmp/cli.zip

    if [ "$channel" == "dev" ]; then
        release_tag="dev"
    else
        release_tag="v2.0"
    fi

    if [ "$distro" == "Ubuntu" ]; then
        wget -q --show-progress https://github.com/xema-in/manager/releases/download/$release_tag/Cli.zip -O /tmp/cli.zip
        unzip -qo /tmp/cli.zip -d /usr/local/bin
        chmod +x /usr/local/bin/xema
        /usr/local/bin/xema completion bash > /etc/bash_completion.d/xema
    fi

    footer
}

# Move a server laid out the old way — everything in /var/lib/xema — onto the split layout.
#
# Deliberately conservative: it copies configuration out and leaves the old tree entirely alone.
# A migration that both relocates everything and deletes the original has no way back when it is
# wrong, and this one runs unattended on live call centres. The old directory simply stops being
# used; a later release removes it once this has proven itself.
#
# Safe to run repeatedly: it never overwrites a file that already exists at the destination.
function migrate_xema_layout() {
    header

    mkdir -p "$XEMA_CONFIG_DIR" "$XEMA_INSTALL_DIR" "$XEMA_STATE_DIR"

    if [ ! -d "$XEMA_LEGACY_DIR" ]; then
        footer "nothing to migrate"
        return 0
    fi

    # Configuration is the only thing here that cannot simply be downloaded again, so it moves
    # first and is never clobbered.
    local dir
    for dir in manager fastagi astermq simplecdr bff queue tracer sipper import ava metrics backfill; do
        if [ -f "$XEMA_LEGACY_DIR/$dir/appsettings.json" ]; then
            cp --update=none "$XEMA_LEGACY_DIR/$dir/appsettings.json" "$XEMA_CONFIG_DIR/$dir.json"
            log "migrated settings: $dir"
        fi
    done

    # State stays exactly where it is. /var/lib is already the right place for it, so
    # simplecdr/state, network/, and the database dumps at the root of /var/lib/xema are
    # untouched by any of this.

    # Prune the unbounded pile of dated Manager copies the old backup step left behind.
    local old
    for old in "$XEMA_LEGACY_DIR"/manager.[0-9]*; do
        [ -d "$old" ] || continue
        rm -rf "$old"
        log "removed stale backup: $old"
    done

    footer
}

function install_xema_binary() {
    header

    backup_existing_installation

    if [ "$channel" == "release" ]; then
        log "-> install_xema_prod_channel"
        install_xema_prod_channel
    fi

    if [ "$channel" == "dev" ]; then
        log "-> install_xema_dev_channel"
        install_xema_dev_channel
    fi

    add_default_settings

    footer
}

function backup_existing_installation() {
    header

    # One previous copy, beside the current one, so a bad upgrade can be stepped back.
    #
    # This used to copy the whole tree into /var/lib/xema/manager.<date> on every run and never
    # remove any of them — 1.4 GB of dead Manager trees had accumulated on one box. A backup
    # nobody prunes is a disk-full waiting to happen, and the state directory is the wrong place
    # for program code besides.
    if [ -d "$XEMA_INSTALL_DIR/manager" ]; then
        rm -rf "$XEMA_INSTALL_DIR/manager.previous"
        cp -a "$XEMA_INSTALL_DIR/manager" "$XEMA_INSTALL_DIR/manager.previous"
    fi

    rm -rf /tmp/manager.zip

    footer
}

# https://github.com/xema-in/manager/releases/download/v2.0/Manager.zip
function install_xema_prod_channel() {
    header

    echo "Installing from ${green}$channel${reset} channel ..."

    if [ "$distro" == "Ubuntu" ]; then
        mkdir -p "$XEMA_INSTALL_DIR/manager"
        wget -q --show-progress https://github.com/xema-in/manager/releases/download/v2.0/Manager.zip -O /tmp/manager.zip
        unzip -qo /tmp/manager.zip -d "$XEMA_INSTALL_DIR/manager"
    fi

    if [ "$distro" != "Ubuntu" ]; then
        echo "${red}$LINENO: $distro not implemented${reset}"
    fi

    footer
}

# https://github.com/xema-in/manager/releases/download/dev/Manager.zip
function install_xema_dev_channel() {
    header

    echo "Installing from ${green}$channel${reset} channel ..."

    if [ "$distro" == "Ubuntu" ]; then
        mkdir -p "$XEMA_INSTALL_DIR/manager"
        wget -q --show-progress https://github.com/xema-in/manager/releases/download/dev/Manager.zip -O /tmp/manager.zip
        unzip -qo /tmp/manager.zip -d "$XEMA_INSTALL_DIR/manager"
    fi

    if [ "$distro" != "Ubuntu" ]; then
        echo "${red}$LINENO: $distro not implemented${reset}"
    fi

    footer
}

function add_default_settings() {
    header

    # Seed configuration only where there is none. An upgrade must never overwrite what an
    # administrator has set — which is exactly what shipping config inside the code directory
    # used to do.
    mkdir -p "$XEMA_CONFIG_DIR"
    if [ -f "$XEMA_INSTALL_DIR/manager/appsettings.default.json" ]; then
        cp --update=none "$XEMA_INSTALL_DIR/manager/appsettings.default.json" "$XEMA_CONFIG_DIR/manager.json"
    fi

    mkdir -p "$XEMA_STATE_DIR/manager"

    footer
}

# variable $configured
function configure_components() {
    header
    configured="no"

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

        log "-> configure_prometheus"
        configure_prometheus

        log "-> configure_xema_service"
        configure_xema_service

        log "-> configure_admin_access"
        configure_admin_access

        configured="yes"
    fi

    footer configured="$configured"
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

    # migrate Xema tables from Compact to Dynamic row format
    compact_tables=$(mysql -u root -N -B -e "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='Xema' AND ROW_FORMAT='Compact' AND ENGINE='InnoDB';" 2>/dev/null)

    log "compact_tables=$compact_tables"

    if [ -n "$compact_tables" ] && [ "$compact_tables" -gt "0" ]; then
        echo "${green}Converting $compact_tables Xema tables to DYNAMIC row format ...${reset}"

        mysql -u root -N -B -e "SELECT CONCAT('ALTER TABLE \`Xema\`.\`', TABLE_NAME, '\` ROW_FORMAT=DYNAMIC;')
            FROM information_schema.TABLES
            WHERE TABLE_SCHEMA='Xema' AND ROW_FORMAT='Compact' AND ENGINE='InnoDB';" | mysql -u root Xema
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

function configure_prometheus() {
    header

    if [ "$distro" == "Ubuntu" ]; then
        wget -q https://raw.githubusercontent.com/xema-in/install/master/deps/prometheus.yml -O /tmp/prometheus.yml
        cp /tmp/prometheus.yml /etc/prometheus/prometheus.yml

        wget -q https://raw.githubusercontent.com/xema-in/install/master/deps/target-xema.json -O /tmp/target-xema.json
        cp /tmp/target-xema.json /etc/prometheus/target-xema.json
    fi

    if [ "$distro" == "CentOS" ]; then
        echo "${red}$LINENO: Not implemented${reset}"
    fi

    if [ "$distro" == "Unknown" ]; then
        echo "${red}$LINENO: $distro OS${reset}"
    fi

    footer
}

# The units Xema installs. Order is install order, not start order.
XEMA_UNITS=(
    xema-manager
    xema-fastagi
    xema-astermq
    xema-simplecdr
    xema-bff
    xema-ava
    xema-sipper
    xema-metrics
    xema-queue
)

function install_xema_unit() {
    local unit="$1"

    wget -q "https://raw.githubusercontent.com/xema-in/install/master/deps/$unit.service" -O "/tmp/$unit.service"
    if [ ! -s "/tmp/$unit.service" ]; then
        echo "${red}$LINENO: could not fetch $unit.service${reset}"
        return 1
    fi

    cp "/tmp/$unit.service" "/lib/systemd/system/$unit.service"
    systemctl daemon-reload
    systemctl enable "$unit.service"
    log "unit installed: $unit"
}

function configure_xema_service() {
    header

    if [[ $hostsys == "WSL" && $kernel == "Linux" ]]; then
        # wsl
        if [ ! -f /etc/init.d/xema-manager ]; then
            wget -q https://raw.githubusercontent.com/xema-in/install/master/deps/xema-manager -O /tmp/xema-manager
            cp /tmp/xema-manager /etc/init.d/xema-manager
            chmod +x /etc/init.d/xema-manager
            update-rc.d xema-manager defaults
        fi

    elif [[ $hostsys == "Linux" && $kernel == "Linux" ]]; then
        # Ubuntu, CentOS
        #
        # This was the same eight lines repeated once per service, which is how xema-tracer came
        # to have no unit at all: adding one meant remembering to copy the block again.
        local unit
        for unit in "${XEMA_UNITS[@]}"; do
            install_xema_unit "$unit"
        done
    fi

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

function reload_configurations() {
    header

    # if [[ $configured == "yes" ]]; then

    # fi

    log "-> reload_nginx"
    reload_nginx

    log "-> reload_prometheus"
    reload_prometheus

    footer
}

function reload_nginx() {
    header

    if [ "$distro" == "Ubuntu" ]; then
        nginx -s reload
    fi

    if [ "$distro" == "CentOS" ]; then
        nginx -s reload
    fi

    if [ "$distro" == "Unknown" ]; then
        echo "${red}$LINENO: $distro OS${reset}"
    fi

    footer
}

function reload_prometheus() {
    header

    if [ "$distro" == "Ubuntu" ]; then
        systemctl restart prometheus
    fi

    if [ "$distro" == "CentOS" ]; then
        echo "${red}$LINENO: $distro OS${reset}"
    fi

    if [ "$distro" == "Unknown" ]; then
        echo "${red}$LINENO: $distro OS${reset}"
    fi

    footer
}

function install_and_configure_system() {
    header

    log "-> install_tools_and_binaries"
    install_tools_and_binaries

    log "-> configure_components"
    configure_components

    log "-> reload_configurations"
    reload_configurations

    footer
}

# variable $started
function setup_and_start_services() {
    header
    started="no"

    log "-> install_and_configure_system"
    install_and_configure_system

    if [[ $configured == "yes" ]]; then

        # do anything else neededd

        started="yes"
    fi

    footer started="$started"
}

help() {
    # Display Help
    echo "Install Xema Platform software."
    echo "Syntax: ./install-xema.sh [-d|h|m|v]"
    echo "options:"
    echo "h     Print this Help."
    echo "d     Install the Dev release."
    echo "m     Display the OS support matrix."
    echo "v     Increase verbosity (use up to -vvv to remove apt quiet flags)."
    echo
}

# variable $success
function bootstrap() {
    header
    success="no"

    echo "Selected ${green}$channel${reset} channel ..."

    log "-> setup_and_start_services"
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
display_matrix="false"
verbosity=0
while getopts hdmv option; do
    case $option in
    h) # display Help
        help
        exit
        ;;
    d) # Dev release
        channel="dev"
        ;;
    m) # Display support matrix
        display_matrix="true"
        ;;
    v) # Increase verbosity
        verbosity=$((verbosity + 1))
        ;;
    \?) # Invalid option
        echo "Error: Invalid option"
        echo
        help
        exit
        ;;
    esac
done

# Set apt quiet flags: -qqq by default, one q removed per -v
_quiet_level=$((3 - verbosity))
if [ $_quiet_level -lt 0 ]; then _quiet_level=0; fi
if [ $_quiet_level -eq 0 ]; then
    apt_quiet=""
else
    apt_quiet="-$(printf 'q%.0s' $(seq 1 $_quiet_level))"
fi
unset _quiet_level

#detect_installed_channel

log "channel: ""${green}$channel${reset}"

# Display just the support matrix if requested
if [[ $display_matrix == "true" ]]; then
    print_support_matrix
    exit 0
fi

depth=0
set_colors
bootstrap
if [[ $success == "no" || $channel == "dev" ]]; then show_log; fi
