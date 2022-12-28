#!/usr/bin/env bash

if [ -z ${BASE_URL} ]; then
    echo "BASE_URL is unset, use VERCEL: '$VERCEL_URL'";
    hugo -b $VERCEL_URL
else
    echo "BASE_URL is set to '$BASE_URL'";
    hugo -b $BASE_URL
fi