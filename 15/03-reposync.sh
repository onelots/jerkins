#!/bin/bash

repo_args="$@"

export CCACHE_MAXSIZE=50G

echo "$repo_args"

source build/envsetup.sh &&
repo sync "$repo_args"