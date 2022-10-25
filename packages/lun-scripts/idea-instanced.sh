#!/bin/bash

set -euo pipefail

instance=${1:-default}
shift
path=/home/lun/.config/idea-instances/$instance

(IDEA_PROPERTIES="$(printf "\t-Didea.system.path=%s/sys\t-Didea.config.path=%s/cfg" "$path" "$path")" \
	idea-ultimate "$@" >/dev/null 2>/dev/null &) &
