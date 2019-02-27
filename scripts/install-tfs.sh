
which curl
if [ "$?" -ne "0" ]
then
  sudo apt update
  sudo apt install -y curl
fi

cd ~

mkdir azagent;cd azagent;curl -fkSL -o vstsagent.tar.gz https://vstsagentpackage.azureedge.net/agent/2.147.1/vsts-agent-linux-x64-2.147.1.tar.gz;tar -zxvf vstsagent.tar.gz; if [ -x "$(command -v systemctl)" ]; then ./config.sh --deploymentgroup --deploymentgroupname "1100 Servers" --acceptteeeula --agent $HOSTNAME --url https://dev.azure.com/xema-in/ --work _work --projectname 'Xema' --auth PAT --token go7lcvvi4wcvx2uq4w5zlnurdq27ohhiwyrfjuzd6iadm3dquyta --runasservice; sudo ./svc.sh install; sudo ./svc.sh start; else ./config.sh --deploymentgroup --deploymentgroupname "1100 Servers" --acceptteeeula --agent $HOSTNAME --url https://dev.azure.com/xema-in/ --work _work --projectname 'Xema' --auth PAT --token go7lcvvi4wcvx2uq4w5zlnurdq27ohhiwyrfjuzd6iadm3dquyta; ./run.sh; fi
