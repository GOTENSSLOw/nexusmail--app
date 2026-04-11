#!/bin/bash
set -e
NAME=${1:?Usage: create-user.sh <username> <password>}
PASS=${2:?Usage: create-user.sh <username> <password>}

sudo useradd -m -s /bin/bash "$NAME"
echo "$NAME:$PASS" | sudo chpasswd
sudo mkdir -p "/home/$NAME/Maildir"/{cur,new,tmp}
sudo chown -R "$NAME:$NAME" "/home/$NAME/Maildir"
sudo chmod -R 700 "/home/$NAME/Maildir"
echo "User $NAME created"
