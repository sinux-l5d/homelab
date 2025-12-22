# v0 architecture: Curious Squirrel
This is the start of my homelab journey. It's cheap and simple to start somewhere.

## Goals
I have a Virtual Private Server on the internet to host a few services, but some services should run on a private network to improve my daily life.
This is also an excuse to have a long-running project that I will keep updating when I have time, or want to learn something.

This version is about providing a first set of services without overthinking the network, which is a topic for v1.

## Hardware
I'm using a spare laptop : MSI Modern 15.
- Connected to my ISP router with a ethernet cable over a USB-C adapter.
- One SSD drive of 426 GiB
- 8 CPU cores
- 8 GiB of RAM

## Networking
This will be simple on purpose:
- the default incusbr0 network will remain unused
- an `external` macvlan network, to connect to the `192.168.1.0/24` of my home network

All instances will in the external, without firewall, network rules or dns.

<!--## Deployment
TODO when mature enough

The deployment is done in 3 parts:
1. deploy infrastructure: networks, pools, volumes, VMs and LXC containers that are not applications (e.g.: Kubernetes cluster).
2. import data backups : if it exists.
3. deploy applications & configuration-->
