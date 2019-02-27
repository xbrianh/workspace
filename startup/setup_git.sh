#!/bin/bash
set -euo pipefail

wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
mv git-completion.bash ~/.git-completion.bash

git clone https://github.com/awslabs/git-secrets.git
(cd git-secrets && sudo make install)
git secrets --register-aws --global

git config --global credential.helper store

echo "source ~/.git-completion.bash" >> ~/.bashrc
