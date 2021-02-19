#!/bin/sh
# script to setup and install Minecraft server scripts

#
# constants
#

LB='\033[1;94m'
RD='\033[1;31m'
GN='\033[1;32m'
YW='\033[1;33m'
NC='\033[0m'

DIR="$(cd "$(dirname "$0")" && pwd)"
ROOTDIR="$DIR/../server"
SERVICEDIR="/etc/systemd/system"
EXECDIR="/usr/local/bin"

#
# creating startup service
#

echo -e "${LB}installing/updating startup service...${NC}"

mkdir -p $SERVICEDIR
cp $DIR/minecraft.service $SERVICEDIR/

# reload daemon cache
systemctl daemon-reload

echo -e "${LB}\tenabling the startup service...${NC}"

while ! [[ $(systemctl is-enabled minecraft) == "enabled" ]]; do
  systemctl enable minecraft
done

#
# setting up server directory
#

echo -e "${LB}setting up server directory...${NC}"

echo -e "${LB}\tcreating directory...${NC}"
mkdir -p $EXECDIR/minecraft

echo -e "${LB}\tsaving server directory path...${NC}"
echo $ROOTDIR | tee $EXECDIR/minecraft/rootpath.txt > /dev/null

#
# updating server scripts 
#

echo -e "${LB}updating server scripts...${NC}"

echo -e "${LB}\tremoving old scripts...${NC}"
rm "$EXECDIR/minecraft/start.sh" >/dev/null 2>&1
rm "$EXECDIR/minecraft/restart.sh" >/dev/null 2>&1

echo -e "${LB}\tretrieving new scripts...${NC}"
cp $DIR/../bin/start.sh $EXECDIR/minecraft
cp $DIR/../bin/restart.sh $EXECDIR/minecraft

#
# installing depedencies
#

echo -e "${LB}installing dependencies...${NC}"

echo -e "${LB}\tinstalling java openjdk...${NC}"
yes | pacman -S --needed jre-openjdk-headless
if ! java -version 2>&1 >/dev/null | egrep "\S+\s+version"; then
  echo -e "${RD}java could not be installed correctly. Aborting.${NC}"
  exit 1
fi

echo -e "${LB}\tinstalling screen...${NC}"
yes | pacman -S --needed screen

echo -e "${LB}\tinstalling ssh...${NC}"
yes | pacman -S --needed openssh
systemctl enable sshd

sed -i "s/.*#.*PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config

printf "1\ny" | pacman -S --needed cron

systemctl enable cronie
systemctl start cronie
croncmd="$EXECDIR/minecraft/restart.sh"
cronjob="0 4 * * * $croncmd"
( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab - >/dev/null 2>&1

echo -e "${YW}The server has been successfully set up. Reboot the system to start or restart the server.${NC}"
