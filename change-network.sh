#!/bin/bash

### Get path of the script
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit; pwd -P )"

### Initialize timer
COUNT=0

### Available script options
OPTIONS="t:c:h"

### Help Message
read -r -d '' HELP << EOT
This script lets you safely test network changes by saving the current config,
copying the changed file and perform a rollback if the script isn't stopped.
If you're happy with the changes you can stop the script by executing the
following command:

touch $SCRIPTPATH/stop

The script also saves the network routes before and immedeately after the
change, as well as halfway through the time the rollback process is
initiated in a file.

The config file that is considered post change has to be located in the folder
the script is located in. By default the name of the file is assumed to be
interfaces.new. However this name can be overwritten.

Usage: change-network.sh [OPTIONS]

Available Options:
-t    Defines the number of seconds the script will wait before performing a
      rollback of the config
-c    Config file
-h    Help Menu
EOT

while getopts ${OPTIONS} opt; do
  case ${opt} in
    t)
      echo "Timer set to ${OPTARG} seconds"
      TIMER=${OPTARG}
      ROUTE_TIMER=$(( TIMER / 2 ))
      ;;
    c)
      echo "Using config file ${OPTARG}"
      CONFIG=${OPTARG}
      ;;
    h)
      echo -e "$HELP"
      ;;
    :)
      echo "Option -${OPTARG} requires an argument."
      exit 1
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 1
      ;;
  esac
done

### Check if timer has been set
if [[ -z $TIMER ]]; then
  echo -e "A timer has to be set!"
  echo -e ""
  echo -e "$HELP"
fi

### Use specified config. If not set use default
CONFIG=${CONFIG:-interfaces.new}

### Getting routing pre change
ip route list > "$SCRIPTPATH/routes.pre"

### Backup configuration
echo "Backup current configuration"
cp /etc/network/interfaces "$SCRIPTPATH/interfaces.bak"

### Initialize changes
echo "Changing network configuration"
cp "$SCRIPTPATH/$CONFIG" /etc/network/interfaces
systemctl restart networking

### Getting routes immediately after the change
ip route list > /root/network/routes.during

### Start looping endlessly
while true; do
  ### Loop timer increase
  COUNT=$(( COUNT + 1 ))

  ### If file exists stop loop to keep changes
  if [[ -f $SCRIPTPATH/stop ]]; then
    echo "Change was successful. Exiting"
    rm "$SCRIPTPATH/stop"
    exit 0
  fi

  ### Getting routes post change
  if [[ $COUNT -eq $ROUTE_TIMER ]]; then
    ip route list > "routes.post"
  fi

  ### Revert changes after timer runs out
  if [[ $COUNT -eq $TIMER ]]; then
    echo "Something went wrong. Reverting changes"
    cp "$SCRIPTPATH/interfaces.bak" /etc/network/interfaces
    systemctl restart networking
    exit 1
  fi

  sleep 1
done
