if [[ `/sbin/init --version` =~ upstart ]]; 
then 
  echo using upstart;
elif [[ `systemctl` =~ -\.mount ]]; 
then 
  echo using systemd;
elif [[ -f /etc/init.d/cron && ! -h /etc/init.d/cron ]]; 
then 
  echo using sysv-init;
else 
  echo cannot tell; 
fi


apt update

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

which asterisk
if [ "$?" -ne "0" ]
then
  apt install -y asterisk
fi

which nginx
if [ "$?" -ne "0" ]
then
  apt install -y nginx
fi

which dotnet
if [ "$?" -ne "0" ]
then

  if [[ $(lsb_release -i) = *Ubuntu* ]]; then

    if [[ $(lsb_release -r) = *18.04* ]]; then
      wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
      dpkg -i /tmp/packages-microsoft-prod.deb
      add-apt-repository universe
    fi

    apt update
  fi

  apt install -y apt-transport-https
  apt install -y dotnet-sdk-2.2
  apt install -y dotnet-sdk-3.1

fi




ls /etc/init.d/xema-manager
if [ "$?" -ne "0" ]
then
  wget -q https://raw.githubusercontent.com/xema-in/install/master/deps/xema-manager -O /tmp/xema-manager
  cp /tmp/xema-manager /etc/init.d/xema-manager
  chmod +x /etc/init.d/xema-manager
  update-rc.d xema-manager defaults
fi

ls /etc/systemd/system/multi-user.target.wants/xema-manager.service
if [ "$?" -ne "0" ]
then
  wget -q https://raw.githubusercontent.com/xema-in/install/master/deps/xema-manager.service -O /tmp/xema-manager.service
  cp /tmp/xema-manager.service /lib/systemd/system/xema-manager.service
  ln -s /lib/systemd/system/xema-manager.service /etc/systemd/system/multi-user.target.wants/xema-manager.service
  systemctl daemon-reload
  systemctl enable xema-manager.service
fi



cp ./scripts/xema.nginx /etc/nginx/sites-available/xema.nginx

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


mkdir /var/lib/xema

