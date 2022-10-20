#!/bin/bash

NAME="honeypot-allinone:ubuntu-22.04"

sudo docker build . -f Dockerfile.22.04 -t $NAME

