#!/bin/bash

docker-compose ps -q "$1" | xargs docker rm -f
docker-compose up -d
