#!/bin/bash

for i in $(seq 1 3); do
  node="test${i}-c1-sfo2"
  docker-machine rm "${node}"
done
