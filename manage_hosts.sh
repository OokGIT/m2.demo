#!/bin/bash
HOSTS='m2.demo m2demo.local'
IPS="$(docker inspect -f '{{.NetworkSettings.IPAddress }}' $(docker ps -q))";
echo  "$HOSTS" "$IPS" >> /etc/hosts

