id -u xema
if [ "$?" -ne "0" ]
then
  useradd xema -m
fi
