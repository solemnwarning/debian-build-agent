#!/bin/bash

HOST="root@vmhost01.lan.solemnwarning.net"
DIR="/mnt/vmbuild/debian-build-agent"

set -e

cd "$(dirname "$0")"

rsync -tpr --delete --exclude-from=.gitignore -e ssh . "$HOST:$DIR"
ssh "$HOST" "$DIR/deploy.sh"
