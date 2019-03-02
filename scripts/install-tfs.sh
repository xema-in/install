id -u xema
if [ "$?" -ne "0" ]
then
  sudo useradd -m -s /bin/bash xema
fi


which curl
if [ "$?" -ne "0" ]
then
  sudo apt update
  sudo apt install -y curl
fi

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
echo "${red}**********${reset}"
echo "${red}Company Name and key are case sensitive.${reset}"
echo "${red}Server Name should contains letters and numbers only. Space or any other special character not allowed.${reset}"
echo "${red}Do not repeat server names.${reset}"
echo "${red}**********${reset}"

IFS="
"
echo "Enter your company name:"
read company

echo "Enter server name:"
read server

echo "Enter your key (PAT):"
read pat

sudo -u xema -- sh -c '

cd /home/xema

mkdir azagent
cd azagent
wget -c https://vstsagentpackage.azureedge.net/agent/2.147.1/vsts-agent-linux-x64-2.147.1.tar.gz
tar -zxvf vsts-agent-linux-x64-2.147.1.tar.gz
if [ -x "$(command -v systemctl)" ]
then 
  ./config.sh --runasservice --unattended --acceptteeeula --deploymentgroup --deploymentgroupname "'$company'" --agent "'$server'" --url https://dev.azure.com/xema-in/ --work _work --projectname 'Xema' --auth PAT --token '$pat'
else 
  ./config.sh                --unattended --acceptteeeula --deploymentgroup --deploymentgroupname "'$company'" --agent "'$server'" --url https://dev.azure.com/xema-in/ --work _work --projectname 'Xema' --auth PAT --token '$pat'
  ./run.sh
fi

'

cd /home/xema/azagent

sudo ./svc.sh install xema
sudo ./svc.sh start
