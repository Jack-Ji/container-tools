#!/bin/bash

if [ $# -ne 2 ]; then
  echo "usage: $0 <Access Key> <Secret Key>"
  exit 1
fi

AK=$1
SK=$2
PASSWD=$(printf "$AK" | openssl dgst -binary -sha256 -hmac "$SK" | od -An -vtx1 | sed 's/[ \n]//g' | sed 'N;s/\n//')
docker login -u cn-east-3@$AK -p $PASSWD swr.cn-east-3.myhuaweicloud.com

