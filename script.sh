which curl
if [ "$?" -ne "0" ]
then
  sudo apt update
  sudo apt install -y curl
fi


