#!/bin/bash

p2 -f yaml -t lb.j2 > lb.yml < config.yml
p2 -f yaml -t hello.j2 > hello.yml < config.yml

docker stack deploy -c lb.yml lb
docker stack deploy -c hello.yml hello
