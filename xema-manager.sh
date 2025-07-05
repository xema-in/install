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
elif [[ $(cat /etc/os-release | grep "^NAME=") = *CentOS* ]]; 
then
  ostype="CentOS"
else
  ostype="Unknown"
fi

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

echo  "${green}"
echo "Detected Init Type: " $inittype
echo "Detected OS Type: " $ostype
echo  "${reset}"



# Install Deps for Ubuntu using apt
if [ "$ostype" == "Ubuntu" ]; then
  # Update APT
  apt update

  # Install Tools
  apt install -y curl wget unzip at git

  # Install Asterisk
  which asterisk
  if [ "$?" -ne "0" ]
  then
    apt install -y asterisk
  fi

  # Install MariaDb
  which mysql
  if [ "$?" -ne "0" ]
  then
    apt install -y mariadb-server
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

    if [[ $(lsb_release -r) = *20.04* ]]; then
      wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
      dpkg -i /tmp/packages-microsoft-prod.deb
    fi

    if [[ $(lsb_release -r) = *22.04* ]]; then
      wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
      dpkg -i /tmp/packages-microsoft-prod.deb
    fi

    if [[ $(lsb_release -r) = *24.04* ]]; then
      wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb -O /tmp/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb
      wget http://archive.ubuntu.com/ubuntu/pool/main/i/icu/libicu66_66.1-2ubuntu2_amd64.deb -O /tmp/libicu66_66.1-2ubuntu2_amd64.deb

      dpkg -i /tmp/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb
      dpkg -i /tmp/libicu66_66.1-2ubuntu2_amd64.deb

      wget https://download.visualstudio.microsoft.com/download/pr/fea239ad-fd47-4764-aa71-6a147a82f632/20ee58b0bf08ae9f6e76e37ba3765c57/dotnet-runtime-3.1.32-linux-x64.tar.gz -O /tmp/dotnet-runtime-3.1.32-linux-x64.tar.gz
      wget https://download.visualstudio.microsoft.com/download/pr/39c3ef4c-73c7-4248-8c54-0865d5feb8b2/3420b1ff6b0f36e63044d6f7a794b579/aspnetcore-runtime-3.1.32-linux-x64.tar.gz -O /tmp/aspnetcore-runtime-3.1.32-linux-x64.tar.gz

      tar zxf /tmp/dotnet-runtime-3.1.32-linux-x64.tar.gz -C /usr/lib/dotnet/
      tar zxf /tmp/aspnetcore-runtime-3.1.32-linux-x64.tar.gz -C /usr/lib/dotnet/
    fi

    apt update
    apt install -y apt-transport-https
    apt install -y aspnetcore-runtime-3.1
    #apt install -y dotnet-sdk-3.1

  fi
elif [ "$ostype" == "CentOS" ]; then

  # Install curl and wget
  which curl
  if [ "$?" -ne "0" ]
  then
    yum install -y curl
  fi
  
  which wget
  if [ "$?" -ne "0" ]
  then
    yum install -y wget
  fi

  which unzip
  if [ "$?" -ne "0" ]
  then
    yum install -y unzip
  fi

  # Install Asterisk
  which asterisk
  if [ "$?" -ne "0" ]
  then
    echo  "${green}"
    echo "Asterisk not found. Automatic installation not supported."
    echo  "${reset}"
  fi

  # Install MariaDb
  which mysql
  if [ "$?" -ne "0" ]
  then
    wget -q https://raw.githubusercontent.com/xema-in/install/master/deps/mariadb.repo -O /etc/yum.repos.d/mariadb.repo
    yum install -y MariaDB-server
    systemctl enable mariadb
    service mariadb start
  fi

  # Install nginx
  which nginx
  if [ "$?" -ne "0" ]
  then
    yum install -y epel-release
    yum install -y nginx
    systemctl enable nginx
    service nginx start
  fi

  # Install dotnet
  which dotnet
  if [ "$?" -ne "0" ]
  then

    if [[ $(cat /etc/os-release | grep "^VERSION_ID=") = *7* ]]; then
      rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
    fi

    yum install -y dotnet-sdk-2.2
    yum install -y dotnet-sdk-3.1

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
  # Ubuntu, CentOS

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

if [ "$ostype" == "Ubuntu" ]; then

  ls /etc/ssl/private/key.pem
  if [ "$?" -ne "0" ]
  then
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/private/key.pem -out /etc/ssl/certs/certificate.pem -subj "/CN=xema-manager"
  fi
  
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
  
elif [ "$ostype" == "CentOS" ]; then

  wget -q https://raw.githubusercontent.com/xema-in/install/master/deps/xema.nginx -O /tmp/xema.nginx
  cp /tmp/xema.nginx /etc/nginx/conf.d/xema.conf

  nginx -s reload

fi

# Disable firewall

if [ "$ostype" == "Ubuntu" ]; then
  echo ""
elif [ "$ostype" == "CentOS" ]; then
  systemctl stop firewalld
  systemctl disable firewalld
  systemctl mask --now firewalld
fi

# Configure logrotate

if [ "$ostype" == "Ubuntu" ]; then
  wget -q https://raw.githubusercontent.com/xema-in/install/master/deps/asterisk-master-csv -O /tmp/asterisk-master-csv
  cp /tmp/asterisk-master-csv /etc/logrotate.d/asterisk-master-csv
elif [ "$ostype" == "CentOS" ]; then
  echo ""
fi


mysql -u root -e "CREATE USER IF NOT EXISTS 'xema'@'localhost' IDENTIFIED BY 'xema';GRANT ALL PRIVILEGES ON *.* TO 'xema'@'localhost';FLUSH PRIVILEGES;"

mkdir -p /var/lib/xema/manager
cp -r /var/lib/xema/manager /var/lib/xema/manager.$(date '+%Y%m%d.%H')

rm -rf /tmp/manager.zip
wget -c https://github.com/xema-in/manager/releases/download/v1.0/Manager.zip -O /tmp/manager.zip
unzip -o /tmp/manager.zip -d /var/lib/xema/manager

cp -n /var/lib/xema/manager/appsettings.default.json /var/lib/xema/manager/appsettings.json

service xema-manager start

ssh-import-id-gh VasuInukollu

