#!/bin/bash
set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DCP_WORKSPACE_HOME="$(cd -P "$(dirname "$SOURCE")" && pwd)"

deployment=${1:-dev}
workspace_name="dcp-workspace-${deployment}"
wid=$(docker ps -a --latest --filter "name=${workspace_name}" --format="{{.ID}}")

if [[ -z $wid ]]; then
    docker pull xbrianh/workspace
    
    wid=$(docker run --name $workspace_name -it --env DEPLOYMENT=$deployment -d xbrianh/workspace)
    
    for name in ".git-credentials" ".aws" ".google"; do
        filename=${HOME}/${name}
        if [[ -d $filename || -f $filename ]]; then
            echo "Found $filename, copying into container"
            docker cp $filename $wid:/home/dcp
        fi
    done
    
    for name in $DCP_WORKSPACE_HOME/dotfiles/*; do
        docker cp $name $wid:/home/dcp/.$(basename $name)
    done
    
    docker cp ${DCP_WORKSPACE_HOME}/startup $wid:/home/dcp/.startup
    docker exec -it -u 0 $wid chown -R dcp:dcp /home/dcp
    docker exec -it $wid /home/dcp/.startup/startup.sh

    docker exec -it $wid  git config --global user.name $(git config user.name)
    docker exec -it $wid  git config --global user.email $(git config user.email)
fi

docker exec -it $wid /bin/bash