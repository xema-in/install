sudo sh ./scripts/setup-sudo.sh

ls /etc/systemd/system/xema-manager.service
if [ "$?" -eq "0" ]
then
  red=`tput setaf 1`
  green=`tput setaf 2`
  reset=`tput sgr0`
  echo "${green}Xema Node already installed.${reset}"
  echo "Continue to run step2.sh to reinstall ..."
fi
