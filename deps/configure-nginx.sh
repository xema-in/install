cp ./scripts/xema.nginx /etc/nginx/sites-available/xema.nginx

ls /etc/nginx/sites-enabled/xema.nginx
if [ "$?" -ne "0" ]
then
  ln -s /etc/nginx/sites-available/xema.nginx /etc/nginx/sites-enabled/xema.nginx
fi

ls /etc/nginx/sites-enabled/default
if [ "$?" -eq "0" ]
then
  rm /etc/nginx/sites-enabled/default
fi

nginx -s reload
