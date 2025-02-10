#!/bin/bash

#
# install ssb-pub image
#
docker pull ahdinosaur/ssb-pub

#
# create sbot container
#
mkdir ~/ssb-pub-data
chown -R 1000:1000 ~/ssb-pub-data

#
# setup sbot config
#
EXTERNAL=$(dig +short myip.opendns.com @resolver1.opendns.com)
cat > ~/ssb-pub-data/config <<EOF
{
  "connections": {
    "incoming": {
      "net": [
        {
          "scope": "public",
          "host": "0.0.0.0",
          "external": "${EXTERNAL}",
          "transform": "shs",
          "port": 8008
        }
      ]
    },
    "outgoing": {
      "net": [
        {
          "transform": "shs"
        }
      ]
    }
  }
}
EOF

#
# create sbot container
#

# create ./create-sbot script
cat > ./create-sbot <<EOF
#!/bin/bash

memory_limit=$(($(free -b --si | awk '/Mem\:/ { print $2 }') - 200*(10**6)))

docker run -d --name sbot \
   -v ~/ssb-pub-data/:/home/node/.ssb/ \
   -p 8008:8008 \
   --restart unless-stopped \
   --memory "\$memory_limit" \
   ahdinosaur/ssb-pub
EOF
# make the script executable
chmod +x ./create-sbot
# run the script
./create-sbot

# create ./sbot script
cat > ./sbot <<EOF
#!/bin/sh

docker exec -it sbot sbot "\$@"
EOF

# make the script executable
chmod +x ./sbot

#
# setup auto-healer
#
docker pull ahdinosaur/healer
docker run -d --name healer \
  -v /var/run/docker.sock:/tmp/docker.sock \
  --restart unless-stopped \
  ahdinosaur/healer

# ensure containers are always running
printf '#!/bin/sh\n\ndocker start sbot\n' | tee /etc/cron.hourly/sbot && chmod +x /etc/cron.hourly/sbot
printf '#!/bin/sh\n\ndocker start healer\n' | tee /etc/cron.hourly/healer && chmod +x /etc/cron.hourly/healer
