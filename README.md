# ssb-pub-underground

Host your own [Secure ScuttleButt (SSB)](https://www.scuttlebutt.nz) pub in a docker container at home

A containerized [ssb-server](https://github.com/ssbc/ssb-server?tab=readme-ov-file) for home server use. Docs [here](https://scuttlebot.io/)

SSB Pubs have generally been deprecated in favor of SSB Rooms.  Primarily, this is because pubs have typically been servers on the internet
to replicate and store SSB feeds, and it may be undesireable to do that publicly. However, there is one excellent use for an SSB pub, 
and that is on a home server so you and your family and friends can keep your feeds synced and backed up.  It seems this is closer to the original vision of SSB 
as a sneakernet gossip social media.  It's not inconceivable that an actual physical pub or library might choose to run a local server on their
wifi.

This is also an experiment to see if [Iroh](https://scuttlebot.io/) can be used to connect two pubs behind NAT firewalls so you can
also connect to your friends' SSB servers to sync, without the typical publicly hosted SSB Pubs and Rooms.  This makes SSB just a little
more decentralized and distributed.  If it works, then SSB can go almost completely "underground".

[ssb-server](https://github.com/ssbc/ssb-server?tab=readme-ov-file) appears to be unmaintained, which could be a security risk, so it is not 
recommended to try to run this publicly, though I am not aware of any issues.  There are other slightly more maintained alternatives, but the 
choice to use it here is influenced by it's [excellent commandline api](https://scuttlebot.io/apis/scuttlebot/ssb.html), which allows the server 
to be used programmatically in various ways, as well as it's plug-in infrastructure.

## Host machine

This package is currently designed to be used on container host machines with [Docker installed](https://docs.docker.com/engine/install/), however
the instructions below are currently for Debian-based host machines.  You may be able to adapt them to your OS. 

## Status

Alpha. Currently creates an ssb server that ddiscoverable on a local network. All interaction with the server is manual by command line, but you can disccover and follow other SSB users via the commandd line.

## Installation and Setup

[Install Docker](https://docs.docker.com/engine/install/) and add yourself to the Docker user group if you haven't already:

```shell
sudo usermod -aG docker $USER 
```
You will need to logout and back in for the above to take effect.

Clone repository:

```shell
git clone https://github.com/FujiroAkakura/ssb-pub-underground.git
cd ssb-pub-underground
```
## Run your server

```shell
docker compose up
```
The first time you run, if all went well, you should see output something like:

```console
sbot  | ssb-server 15.3.0 /root/.ssb logging.level:notice
sbot  | my key ID: tGbhTpwDQnr4N7PtztHL17Wi6QXBze8VHUfl5KobUCw=.ed25519
sbot  | ssb-friends: stream legacy api used
```

*my key ID:* is the public address of your server.  Since SSB agents (clients and servers) can discover each other on 
local networks, you should see this ID show up in your client software (check that software for where to look). 


## Your server data

The first time you run the server, a subdirectory called "data" will be created on your container host machine.  This is where your server
will store data, including your secret key.  You will need to move these files if you want to move to a new machine while preserving
the setup. Otherwise, any updates to this code should reuse this setup.

## Your server configuration

The configuration file used by ssb-server is mapped to the "config" subdirectory.  It is not recommended that you edit this at this time.

## Interacting with the container

### Enter a container shell

As long as your server is running, you can enter a shell inside it and access the ssb-server(sbot) API:

```shell
docker exec -it <container id> sbot bash
```

### Get your identity

```shell
sbot whoami
```
### Get your address

```shell
sbot getAddress
```
See: [multiserver address](https://github.com/ssbc/multiserver#address-format)

### Publish a post

```shell
sbot publish --type post --text "My First Post!"
```

### Get gossip peers

```shell
sbot gossip.peers
```

See [this article](https://medium.com/@miguelmota/getting-started-with-secure-scuttlebut-e6b7d4c5ecfd) for more commands like this.

### Follow others

Here is the main reason for this package - to follow and backup you and your family and friend's feeds:

```shell
sbot publish --type contact --contact {feedId} --following
```
where {feedId} is the "@....." address of those you want to follow.

### View your feed, ordered by publish time

```shell
sbot feed
```

### Stream all messages in all feeds, ordered by receive time
```shell
sbot log
```
### Same as above, but keep feeding as messages come in
```shell
sbot log --live
```

### See also sbot help

```shell
sbot --help
```
Note that there are some undocumented commands.

### More on the web

Descriptions of commands your server can run are scattered all over, but the following references describe the CLI API.  Note that some refer to "ssb-server", but use "sbot" instead.  Some commands, like create invite will not work, since only a pub served on the internet can create invites.

https://medium.com/@miguelmota/getting-started-with-secure-scuttlebut-e6b7d4c5ecfd
https://scuttlebot.io/apis/scuttlebot/ssb.html?ref=https://githubhelp.com
https://github.com/fraction/ssb-cli
https://handbook.scuttlebutt.nz/guides/ssb-server/cli-first-steps
https://handbook.scuttlebutt.nz/guides/ssb-server/update-your-profile


## TO-DOs

* [ ] Possibly autofollow local peers as they show up [gossip.changes](
https://medium.com/@miguelmota/getting-started-with-secure-scuttlebut-e6b7d4c5ecfd)
* [ ] Fix error with sodium-native. See [this](https://github.com/ssbc/ssb-server/issues/676) and [this](https://github.com/ssbc/ssb-server/pull/723)
* [ ] Review and implement https://github.com/ssbc/ssb-config/#connections
* [ ] Get [ssb-viewer](https://github.com/ssbc/ssb-viewer) per [ahdinosaur](https://github.com/ahdinosaur) working with latest source code available
* [ ] Get healer per [ahdinosaur](https://github.com/ahdinosaur) working
* [ ] Integrate this? https://github.com/soapdog/ssb-client-for-browser?tab=readme-ov-file

## Attribution

Forked from [ahdinosaur](https://github.com/ahdinosaur)'s [ssb-pub](https://github.com/ahdinosaur/ssb-pub) which was designed to 
install a pub on Digital Ocean, but since public pubs have fallen into of disfavor, it is unmaintained.  The Digital Ocean / Kubernetes / Docker Install code has been removed. Migrated to Docker Compose and eliminated Debian-based scripts on the host to generalizee the setup. 

Used some tricks from: [Docker-ssb-server](https://github.com/Emceelamb/docker-ssb-server/tree/main)

