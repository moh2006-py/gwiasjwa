#!/bin/sh
# script to start the server

#
# constants
#

LB='\033[1;94m'
GN='\033[1;32m'
NC='\033[0m'

EXECDIR="/usr/local/bin"
ROOTDIR="$(cat $EXECDIR/minecraft/rootpath.txt)"
VERFILE="$ROOTDIR/server.version"
numBackups="$(grep -i '^num-backups' $ROOTDIR/server.config | cut -d'=' -f2)"

#
# backing up server
#

echo -e "${LB}backing up server...${NC}"
# sanity check
mkdir -p $ROOTDIR/backups
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

# copy world into timestamped folder
cp -r $ROOTDIR/saves/* $ROOTDIR/backups/$timestamp > /dev/null

# delete old worlds
ls -t $ROOTDIR/backups | tail -n +$(($numBackups + 1)) | xargs printf "$ROOTDIR/backups/%s\n" | xargs -d '\n' rm -r

#
# server prechecking
#

echo -e "flushing system memory..."
sh -c "echo 1 > /proc/sys/vm/drop_caches"
sync

#
# getting latest vanilla version
#

# verify version file
touch $VERFILE

echo -e "getting the latest vanilla version..."

latestServer="$(curl -s https://www.minecraft.net/en-us/download/server/ | grep -m1 '<a.*minecraft_server.*\.jar.*</a>')"

# quit script if no internet connection is present!
[[ -z $latestServer ]] && exit 1

link=$(echo $latestServer | sed -e 's/^.*href="//' -e 's/".*//')
latestVersion=$(echo $latestServer | sed -e 's/^.*>.*minecraft_server\.//' -e 's/\.jar.*//')

echo -e "latest version is ${LB}$latestVersion${NC}."

useFabric="$(grep -i '^enable-fabric' $ROOTDIR/server.config | cut -d'=' -f2)"
if [ $useFabric = "true" ]; then

  curl -s https://maven.fabricmc.net/net/fabricmc/fabric-installer/0.5.2.40/fabric-installer-0.5.2.40.jar -o $ROOTDIR/fabric.jar
  java -jar $ROOTDIR/fabric.jar server -downloadMinecraft -noprofile -dir $ROOTDIR/

else

  #
  # check if latest version is higher than the current version
  #
  
  currentVersion="$(cat $VERFILE)"
  
  rx='^([0-9]+\.){0,2}(\*|[0-9]+)$'
  if ! [[ $currentVersion =~ $rx ]]; then currentVersion="0.0.0"; fi
  
  echo -e "current server version is ${LB}$currentVersion${NC}."
  
  #
  # if latest version > current version, update current version and replace the current server
  #
  
  function versionCompare () {
    if [[ $1 == $2 ]]; then return 0; fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do ver1[i]=0; done
  
    for ((i=0; i<${#ver1[@]}; i++)); do
      # fill empty fields in ver2 with zeros
      if [[ -z ${ver2[i]} ]]; then ver2[i]=0; fi
  
      if ((10#${ver1[i]} > 10#${ver2[i]})); then return 1; fi
      if ((10#${ver1[i]} < 10#${ver2[i]})); then return 2; fi
    done
    return 0
  }
  
  echo "comparing latest version to current version..."
  
  versionCompare $latestVersion $currentVersion
  
  if [[ $? == 1 ]]; then # greater than means 1
    echo "$latestVersion > $currentVersion"
    echo $latestVersion > $VERFILE
  
    echo "installing latest version..."
    curl -s $link -o $ROOTDIR/server.jar
  else
    echo "current version is up to date. Using current version."
  fi

fi

#
# starting server
#

memMax="$(grep -i '^max-mem-alloc' $ROOTDIR/server.config | cut -d'=' -f2)G"
memMin="$(grep -i '^min-mem-alloc' $ROOTDIR/server.config | cut -d'=' -f2)G"

echo -e "\n${GN}starting server.${NC} To view server from root, type ${LB}screen -r minecraft${NC}. To minimize the window, type ${LB}CTRL-A CTRL-D${NC}."

exe=$ROOTDIR/server.jar

if [ $useFabric = "true" ]; then
  exe=$ROOTDIR/fabric-server-launch.jar
fi

cd $ROOTDIR
nice -n -20 screen -dmS minecraft java -server -Xmx$memMax -Xms$memMin -jar $exe nogui
