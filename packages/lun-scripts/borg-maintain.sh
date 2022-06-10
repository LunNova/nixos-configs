#!/bin/bash
set -xeuo pipefail

borg info -- "$1"
borg prune --keep-last 1000000000 --progress -- "$1"
borg compact --progress -- "$1"
