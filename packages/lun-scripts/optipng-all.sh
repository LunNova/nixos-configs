#!/bin/bash
set -xeuo pipefail

exec find . -name "*.png" -exec optipng '{}' '+'
