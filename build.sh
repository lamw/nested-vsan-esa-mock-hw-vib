#!/bin/bash

COLOR='\033[0;32m'
NOCOLOR='\033[0m'

if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo"
  exit
fi

echo -e "${COLOR}Creating Nested vSAN ESA Mock HW VIB build container${NOCOLOR} ..."
docker rmi -f vsanesamockvib
rm -rf artifacts
docker build -t vsanesamockvib .
mkdir -p artifacts
chown vmware:vmware artifacts
docker run -i -v ${PWD}/artifacts:/artifacts vsanesamockvib sh << COMMANDS
cp nested-vsan-esa-mock-hw* /artifacts
COMMANDS
