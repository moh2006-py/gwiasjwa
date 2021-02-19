#!/bin/sh

LB='\033[1;94m'
NC='\033[0m'

echo -e "Local: ${LB}$(ip a | awk '/state UP/{getline; getline; print $2}' | cut -d '/' -f1)${NC}"
echo -e "Broadcasted: ${LB}$(curl -s ifconfig.me)${NC}"
