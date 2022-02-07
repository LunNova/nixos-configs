#!/usr/bin/env bash

id=${1,,}
name="${id^}"

if [ "$email" = "" ]; then
    email="git-${name,,}@lunnova.dev"
fi

export GIT_COMMITTER_NAME="$name"
export GIT_COMMITTER_EMAIL="$email"
export GIT_AUTHOR_NAME="$name"
export GIT_AUTHOR_EMAIL="$email"

exec "${@:2}"
