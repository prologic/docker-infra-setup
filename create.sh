#!/bin/bash

set -x

API_KEY="XXX"

function get_interface_address() {
  node="${1}"
  iface="${2}"

  docker-machine ssh "${node}" /sbin/ip -4 addr show "${iface}" \
    | grep inet \
    | awk '{ print $2 }' \
    | cut -f 1 -d '/'
}

function create_instance() {
  name="${1}"

  docker-machine create \
    --driver=digitalocean \
    --digitalocean-image="rancheros" \
    --digitalocean-size="1gb" \
    --digitalocean-region="sfo2" \
    --digitalocean-ssh-user="rancher"\
    --digitalocean-private-networking \
    --digitalocean-access-token="${API_KEY}" \
    "${name}"
}

function create_manager() {
  node="${1}"

  eval "$(docker-machine env "${node}")"
  ip="$(get_interface_address "${node}" "eth1")"
  docker swarm init --advertise-addr "${ip}" &> /dev/null || exit 1
  token="$(docker swarm join-token -q worker)"
  echo "${token} ${ip}:2377"
}

function create_worker() {
  node="${1}"
  token_endpoint="${2}"

  token="$(echo "${token_endpoint}" | awk '{ print $1 }')"
  endpoint="$(echo "${token_endpoint}" | awk '{ print $2 }')"

  eval "$(docker-machine env "${node}")"
  docker swarm join --token "${token}" "${endpoint}"
}

token_endpoint=""
for i in $(seq 1 3); do
  node="test${i}-c1-sfo2"
  create_instance "${node}"
  if [[ ! "${token_endpoint}" ]]; then
    token_endpoint="$(create_manager "${node}")"
  else
    create_worker "${node}" "${token_endpoint}"
  fi
done
