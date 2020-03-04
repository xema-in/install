#!/bin/bash

# Detect Init System Type
if [[ `/sbin/init --version` =~ upstart ]];
then
  inittype="upstart"
elif [[ `systemctl` =~ -\.mount ]];
then
  inittype="systemd"
elif [[ -f /etc/init.d/cron && ! -h /etc/init.d/cron ]];
then
  inittype="sysv"
else
  inittype="Unknown"
fi

# Detect OS Type
if [[ $(lsb_release -i) = *Ubuntu* ]]; 
then
  ostype="Ubuntu"
else
  ostype="Unknown"
fi

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

echo  "${red}"
echo "Detected Init Type: " $inittype
echo "Detected OS Type: " $ostype
echo  "${reset}"



# Install Deps for Ubuntu using apt
if [ "$ostype" == "Ubuntu" ]; then
  # Update APT
  apt update

  # Install curl and wget
  which curl
  if [ "$?" -ne "0" ]
  then
    apt install -y curl
  fi

  which wget
  if [ "$?" -ne "0" ]
  then
    apt install -y wget
  fi

  which unzip
  if [ "$?" -ne "0" ]
  then
    apt install -y unzip
  fi

  # Install Asterisk
  which asterisk
  if [ "$?" -ne "0" ]
  then
    apt install -y asterisk
  fi

  # Install nginx
  which nginx
  if [ "$?" -ne "0" ]
  then
    apt install -y nginx
  fi

  # Install dotnet
  which dotnet
  if [ "$?" -ne "0" ]
  then

    if [[ $(lsb_release -r) = *18.04* ]]; then
      wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
      dpkg -i /tmp/packages-microsoft-prod.deb
      add-apt-repository universe
    fi

    apt update
    apt install -y apt-transport-https
    apt install -y dotnet-sdk-2.2
    apt install -y dotnet-sdk-3.1

  fi
fi


if [ "$inittype" == "sysv" ]; 
then
  # WSL

  ls /etc/init.d/xema-manager
  if [ "$?" -ne "0" ]
  then
    wget -q https://raw.githubusercontent.com/xema-in/install/master/deps/xema-manager -O /tmp/xema-manager
    cp /tmp/xema-manager /etc/init.d/xema-manager
    chmod +x /etc/init.d/xema-manager
    update-rc.d xema-manager defaults
  fi

elif [ "$inittype" == "systemd" ];
then
  # Ubuntu

  ls /etc/systemd/system/multi-user.target.wants/xema-manager.service
  if [ "$?" -ne "0" ]
  then
    wget -q https://raw.githubusercontent.com/xema-in/install/master/deps/xema-manager.service -O /tmp/xema-manager.service
    cp /tmp/xema-manager.service /lib/systemd/system/xema-manager.service
    ln -s /lib/systemd/system/xema-manager.service /etc/systemd/system/multi-user.target.wants/xema-manager.service
    systemctl daemon-reload
    systemctl enable xema-manager.service
  fi

fi

# Configure nginx
wget -q https://raw.githubusercontent.com/xema-in/install/master/deps/xema.nginx -O /tmp/xema.nginx
cp /tmp/xema.nginx /etc/nginx/sites-available/xema.nginx

ls /etc/nginx/sites-enabled/xema.nginx
if [ "$?" -ne "0" ]
then
  ln -s /etc/nginx/sites-available/xema.nginx /etc/nginx/sites-enabled/xema.nginx
fi

ls /etc/nginx/sites-enabled/default
if [ "$?" -eq "0" ]
then
  rm /etc/nginx/sites-enabled/default
fi

nginx -s reload


mkdir -p /var/lib/xema/manager/Files

wget -c https://github.com/xema-in/manager/releases/latest/download/Manager.zip -O /tmp/manager.zip
unzip -o /tmp/manager.zip -d /var/lib/xema/manager

