# m2.demo
Magento2 + Sample Data - Docker container

Environment: Ubuntu 15.10, Nginx1.9, Php7.0.3, MySQL5.6

build up with #   docker build -t m2 .
run with #        docker run -d -p 80:80 -v /etc/hosts:/hosts -t m2

to make available from docker-host via http:, please run something like:

HOSTS='m2.demo m2demo.local'
IPS="$(docker inspect -f '{{.NetworkSettings.IPAddress }}' $(docker ps -q))";
echo "$HOSTS" "$IPS" >> /etc/hosts

hostnames in Nginx's configuration are: m2.demo & m2demo.local (in Chrome m2.demo makes to search "m2.demo" instead of resolving IP of container).

(manage_hosts.sh included in this reposytory)
