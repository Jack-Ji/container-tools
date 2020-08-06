#!/bin/bash

export DOMAIN=swarmpit.sys.example.com
export NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')

docker node update --label-add swarmpit.db-data=true $NODE_ID
docker node update --label-add swarmpit.influx-data=true $NODE_ID
docker stack deploy --with-registry-auth -c docker-compose.yaml swarmpit
