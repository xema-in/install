id -u xema
if [ "$?" -ne "0" ]
then
  sudo useradd xema -m
fi


which curl
if [ "$?" -ne "0" ]
then
  sudo apt update
  sudo apt install -y curl
fi

sudo -u xema -- sh -c '

cd /home/xema

mkdir azagent
cd azagent
curl -fkSL -o vstsagent.tar.gz https://vstsagentpackage.azureedge.net/agent/2.147.1/vsts-agent-linux-x64-2.147.1.tar.gz
tar -zxvf vstsagent.tar.gz

./config.sh --deploymentgroup --deploymentgroupname "1100 Servers" --acceptteeeula --agent $HOSTNAME --url https://dev.azure.com/xema-in/ --work _work --projectname Xema --auth PAT --token fdt5a6p2k7hhrlex2lhuqx4yju6gxqzzwflmatsnh5wgn4kzd3ga --runasservice

'

sudo /home/xema/azagent/svc.sh install xema
sudo /home/xema/azagent/svc.sh start
