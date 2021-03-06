#!/bin/bash
echo $(ls -alh ${tmp_private_key})

# This script is intended to run once during container startup
set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
home="$(cd -P "$(dirname "$SOURCE")" && pwd)"

# Execute startup scripts
for name in $home/*; do
    echo $name
    if [[ $(basename $name) != "startup.sh" ]]; then
        if [[ -x $name ]]; then
            $name
        fi
    fi
done

# install vim plugins
vim +PluginInstall +qall 2>&1 > /dev/null

# configure the GCP project
gcp_project=$(cat ~/.startup/config.json | jq -r .profiles.${DEPLOYMENT}.gcp_project)
gcloud config set project ${gcp_project}

if [[ -d ~/.aws ]]; then
    # set the AWS_PROFILE env var, inline into bashrc
    aws_profile=$(cat ~/.startup/config.json | jq -r .profiles.${DEPLOYMENT}.aws_profile)
    echo "export AWS_PROFILE=${aws_profile}" >> ~/.bashrc
fi

venv="dcp"
mkdir ~/.virtualenvs
venv_dir=~/.virtualenvs/${venv}
/usr/local/bin/virtualenv -p /usr/bin/python3 ${venv_dir}

# Clone repos
for repo in $(cat ~/.startup/config.json | jq -r .repositories[].url); do
    branch=$(cat ~/.startup/config.json | jq -r --arg n $repo '.repositories[] | select(.url==$n)' | jq -r .deployments.${DEPLOYMENT}.branch)
    git clone --branch ${branch} $repo
    repo_name=$(basename $repo | cut -d '.' -f 1)
	repo_home=$(pwd -P)/$repo_name
done
