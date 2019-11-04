#!/usr/bin/env zsh
set -x

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
project_dir=$(cd "$dir/" 2> /dev/null && pwd -P)

# run swiftformat to format Swift files
swiftformat $project_dir/captions --indent 2
swiftformat $project_dir/captions-example --indent 2

set +x
