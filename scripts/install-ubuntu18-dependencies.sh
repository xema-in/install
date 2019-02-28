which asterisk
if [ "$?" -ne "0" ]
then
  apt install -y asterisk
fi

which java
if [ "$?" -ne "0" ]
then
  apt install -y openjdk-8-jre
fi

which wget
if [ "$?" -ne "0" ]
then
  apt install -y wget
fi

which dotnet
if [ "$?" -ne "0" ]
then
  wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
  dpkg -i packages-microsoft-prod.deb
  
  add-apt-repository universe
  apt-get install -y apt-transport-https
  apt-get update
  apt-get install -y dotnet-sdk-2.2
fi

