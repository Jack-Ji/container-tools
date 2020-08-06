#!/bin/bash

export NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
export EMAIL=admin@example.com
export DOMAIN=traefik.sys.example.com
export USERNAME=admin
export PASSWORD=123456
export HASHED_PASSWORD=$(openssl passwd -apr1 $PASSWORD)

docker network create --driver=overlay traefik-public
docker node update --label-add traefik-public.traefik-public-certificates=true $NODE_ID
docker stack deploy --with-registry-auth -c docker-compose.yaml traefik
