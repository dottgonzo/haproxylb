#!/bin/bash

IMAGE_NAME="dottgonzo/haproxylb"
VERSION="0.1.0"



docker buildx build --platform linux/amd64,linux/arm64 -t ${IMAGE_NAME}:${VERSION} . --push