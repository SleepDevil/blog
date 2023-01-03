#!/usr/bin/env bash
echo "VERCEL_GIT_COMMIT_REF: $VERCEL_GIT_COMMIT_REF"

if [[ "$VERCEL_GIT_COMMIT_REF" == "gh-pages" ]] ; then
  # Don't build
    echo "× build stop beacause of github page branch"
  exit 0;
  else
  # Proceed with the build
    exit 1;
fi

if [ -z ${BASE_URL} ]; then
    echo "BASE_URL is unset, use VERCEL: '$VERCEL_URL'";
    hugo -b $VERCEL_URL
else
    echo "BASE_URL is set to '$BASE_URL'";
    hugo -b $BASE_URL
fi