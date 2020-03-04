ls /etc/systemd/system/xema-manager.service
if [ "$?" -ne "0" ]
then
  cp ./scripts/xema-manager.service /etc/systemd/system/xema-manager.service  
  systemctl daemon-reload
  systemctl enable xema-manager.service
fi

