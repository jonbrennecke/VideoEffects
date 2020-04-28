#!/usr/bin/env zsh
set -x

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
project_dir=$(cd "$dir/" 2> /dev/null && pwd -P)

# run swiftformat to format Swift files
swiftformat $project_dir/VideoEffects --indent 2  --maxwidth 120
swiftformat $project_dir/example --indent 2  --maxwidth 120

set +x
