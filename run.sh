#!/bin/bash



  # System configuration
if grep -qF "fs.inotify.max_user_watches" /etc/sysctl.conf; then
  echo $(grep -F "fs.inotify.max_user_watches" /etc/sysctl.conf)
else
  echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf
fi
sudo sysctl -p




# Run Odoo
#docker-compose -f ./docker-compose.yml up -d

#sudo chmod -R 777 $DESTINATION/addons
sudo chmod -R 777 ./config
sudo chmod -R 777 ./addon_tools
sudo chmod -R 777 ./pgbouncer


