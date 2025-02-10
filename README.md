# ssb-pub-underground

Host your own [Secure ScuttleButt (SSB)](https://www.scuttlebutt.nz) pub in a docker container at home

**NOT WORKING YET - PRE ALPHA - DO NOT USE**

A containerized [ssb-server](https://github.com/ssbc/ssb-server?tab=readme-ov-file). Docs [here](https://scuttlebot.io/)

SSB Pubs have generally been deprecated in favor of SSB Rooms.  Primarily, this is because pubs replicate and store SSB feeds, and
it may be undesireable to do that publicly. However, there is one excellent use for an SSB pub, and that is on a home server
so you and your family and friends can keep your feeds synced.  It seems this is closer to the original vision of SSB.

This is also an experiment to see if [Iroh](https://scuttlebot.io/) can be used to connect two pubs behind NAT firewalls so you can
also connect to your friends' SSB servers to sync, without the typical publicly hosted SSB Pubs and Rooms.  This makes SSB just a little
more decentralized and distributed.  If it works, then SSB can go almost completely "underground".

## table of contents

- [manual setup](#manual-setup)
  - [install docker](#install-docker)
  - [install `ssb-pub` image](#install-ssb-pub-image)
  - [create `sbot` container](#create-sbot-container)
  - [setup auto-healer](#setup-auto-healer)
  - [ensure containers are always running](#ensure-containers-are-always-running)
  - [(optional) add `ssb-viewer` plugin](#optional-add-ssb-viewer)
- [kubernetes setup](#kubernetes-setup)
- [command and control](#command-and-control)
  - [create invites](#create-invites)
  - [stop, start, restart containers](#stop-start-restart-containers)


## manual setup

### install docker

https://docs.docker.com/engine/install/

### install `ssb-pub-underground` image

#### (option a) pull image from docker hub

```shell
docker pull FujiroAkakura/ssb-pub-underground
```

#### (option b) build image from source

from GitHub:

```shell
git clone https://github.com/FujiroAkakura/ssb-pub-underground.git
cd ssb-pub-underground
docker build -t FujiroAkakura/ssb-pub-underground .
```

### create `sbot` container

#### step 1. create a directory on the docker host for persisting the pub's data

```shell
mkdir ~/ssb-pub-data
chown -R 1000:1000 ~/ssb-pub-data
```

> if migrating from an old server, copy your old `secret` and `gossip.json` (maybe also `blobs`) now.
>
> ```
> rsync -avz ~/ssb-pub-data/blobs/sha256/ $HOST:~/ssb-pub-data/blobs/sha256/
> ```

#### step 2. setup ssb config

```shell
EXTERNAL=<hostname.yourdomain.tld>

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
```

#### step 3. run the container

create a `./create-sbot` script:

```shell
cat > ./create-sbot <<EOF
#!/bin/bash

memory_limit="\$((\$(free -b --si | awk '/Mem\:/ { print \$2 }') - 200*(10**6)))"

docker run -d --name sbot \
   -v ~/ssb-pub-data/:/home/node/.ssb/ \
   -p 8008:8008 \
   --restart unless-stopped \
   --memory "\$memory_limit" \
   FujiroAkakura/ssb-pub-underground
EOF
```

where

- `--memory` sets an upper memory limit of your total memory minus 200 MB (for example: on a 1 GB server this could be simplified to `--memory 800m`)

then

```shell
# make the script executable
chmod +x ./create-sbot
# run the script
./create-sbot
```

#### step 4. create `./sbot` script

we will now create a shell script in `./sbot` to help us command our Scuttlebutt server running:

```shell
# create the script
cat > ./sbot <<EOF
#!/bin/sh

docker exec -it sbot sbot \$@
EOF
```

then

```shell
# make the script executable
chmod +x ./sbot
# test the script
./sbot whoami
```

### setup auto-healer

the `ssb-pub-underground` has a built-in health check: `sbot whoami`.

when `sbot` becomes unhealthy (it will!), we want to kill the container, so it will be automatically restarted by Docker.

for this situation, we will use [somarat/healer](https://github.com/somarat/healer):

```shell
docker pull ahdinosaur/healer
```

```shell
docker run -d --name healer \
  -v /var/run/docker.sock:/tmp/docker.sock \
  --restart unless-stopped \
  ahdinosaur/healer
```

### ensure containers are always running

sometimes the `sbot` or `healer` containers will stop running (despite `--restart unless-stopped`!).

for this sitaution, we will setup two cron job scripts:

```shell
printf '#!/bin/sh\n\ndocker start sbot\n' | tee /etc/cron.hourly/sbot && chmod +x /etc/cron.hourly/sbot
printf '#!/bin/sh\n\ndocker start healer\n' | tee /etc/cron.hourly/healer && chmod +x /etc/cron.hourly/healer
```

because `docker start <service>` is [idempotent](https://en.wikipedia.org/wiki/Idempotent), it will not change anything if the service is already running, but if the service is not running it will start it.

### (optional) add `ssb-viewer` plugin

enter your `sbot` container with:

```shell
docker exec -it sbot bash
```

then run:

```shell
npm install -g git-ssb
mkdir -p ~/.ssb/node_modules
cd ~/.ssb/node_modules
git clone ssb://%MeCTQrz9uszf9EZoTnKCeFeIedhnKWuB3JHW2l1g9NA=.sha256 ssb-viewer
cd ssb-viewer
npm install
sbot plugins.enable ssb-viewer
```

edit your config to include

```json
{
  "plugins": {
    "ssb-viewer": true
  },
  "viewer": {
    "host": "0.0.0.0"
  }
}
```

edit your `./create-sbot` to include `-p 8807:8807`.

stop, remove, and re-create sbot:

```shell
docker stop sbot
docker rm sbot
./create-sbot
```

From here you can invoke any of the commands detailed below.

## command and control

### create invites

from your server:

```shell
./sbot invite.create 1
```

from your local machine, using ssh:

```shell
ssh -t root@server ./sbot invite.create 1
```

### start, stop, restart containers

for `sbot`

- `docker stop sbot`
- `docker start sbot`
- `docker restart sbot`

for `healer`

- `docker stop healer`
- `docker start healer`
- `docker restart healer`

## upgrading

### update `ssb-pub-underground` image

```shell
docker pull ahdinosaur/ssb-pub
docker stop sbot
docker rm sbot
# edit ~/ssb-pub-data/config if necessary
./create-sbot
```
