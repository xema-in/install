sudo sh ./scripts/setup-sudo.sh

ls /etc/systemd/system/xema-manager.service
if [ "$?" -eq "0" ]
then
  echo "Xema Node already installed."
  echo "Continue to run step2.sh to reinstall ..."
fi
