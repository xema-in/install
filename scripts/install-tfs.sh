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

sudo -u xema -- sh -c '

cd /home/xema

mkdir azagent;cd azagent;curl -fkSL -o vstsagent.tar.gz https://vstsagentpackage.azureedge.net/agent/2.147.1/vsts-agent-linux-x64-2.147.1.tar.gz;tar -zxvf vstsagent.tar.gz; if [ -x "$(command -v systemctl)" ]; then ./config.sh --unattended --deploymentgroup --deploymentgroupname "1100 Servers" --acceptteeeula --agent $HOSTNAME --url https://dev.azure.com/xema-in/ --work _work --projectname 'Xema' --auth PAT --token fdt5a6p2k7hhrlex2lhuqx4yju6gxqzzwflmatsnh5wgn4kzd3ga --runasservice; else ./config.sh --unattended --deploymentgroup --deploymentgroupname "1100 Servers" --acceptteeeula --agent $HOSTNAME --url https://dev.azure.com/xema-in/ --work _work --projectname 'Xema' --auth PAT --token fdt5a6p2k7hhrlex2lhuqx4yju6gxqzzwflmatsnh5wgn4kzd3ga; ./run.sh; fi

'

cd /home/xema/azagent

sudo ./svc.sh install xema
sudo ./svc.sh start
