#!/usr/bin/env bash

# Script to disable compression and CoW for existing btrfs directory
# Usage: ./script.sh /path/to/directory

set -euo pipefail

error_exit() {
	echo "Error: $1" >&2
	exit 1
}

# Check arguments
if [ $# -ne 1 ]; then
	error_exit "Usage: $0 <directory>"
fi

dir="$1"

# Validate directory exists
if [ ! -d "$dir" ]; then
	error_exit "Directory '$dir' does not exist"
fi

# Check if we have required tools
command -v btrfs >/dev/null 2>&1 || error_exit "btrfs command not found"
command -v chattr >/dev/null 2>&1 || error_exit "chattr command not found"

echo "Disabling compression and CoW for: $dir"

if ! btrfs property set "$dir" compression ""; then
	error_exit "Failed to set compression property on directory"
fi

if ! find "$dir" -exec btrfs property set {} compression "" \;; then
	error_exit "Failed to set compression on directory contents"
fi

if ! chattr +C "$dir" 2>/dev/null; then
	echo "Warning: Could not set +C attribute on directory" >&2
fi

if ! find "$dir" -exec chattr +C {} \;; then
	echo "Warning: Some files may not support +C attribute" >&2
fi

# Defragment to apply compression changes and consolidate extents
echo "Defragmenting to apply changes..."
if ! btrfs filesystem defragment -r "$dir"; then
	error_exit "Defragmentation failed"
fi

echo "Complete! Compression and CoW disabled for $dir"
