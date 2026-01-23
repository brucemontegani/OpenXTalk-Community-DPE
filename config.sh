#!/bin/sh
set -e
base=$(dirname "$0")
exec python3 "${base}/config.py" "$@"
