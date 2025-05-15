#!/bin/bash
set -e
apt-get update
apt-get install -y curl

BASEURL="https://ollama.com/library"
MODEL="$(echo "${1}" | cut -d':' -f1)"
TAG="$(echo "${1}" | cut -s -d':' -f2-)"

if [ "${MODEL}" = "all" ]; then
  for MODEL in $(curl -s "${BASEURL}" | grep -oP 'href="/library/\K[^"]+'); do
    for TAG in $(curl -s "${BASEURL}/${MODEL}/tags" | grep -oP "/library/${MODEL}:\K.*(?=\")"); do
      /bin/ollama pull "${MODEL}:${TAG}"
    done
  done
elif [ -z "${TAG}" ]; then
  for TAG in $(curl -s "${BASEURL}/${MODEL}/tags" | grep -oP "/library/${MODEL}:\K.*(?=\")"); do
    /bin/ollama pull "${MODEL}:${TAG}"
  done
else
  /bin/ollama pull "${MODEL}:${TAG}"
fi
