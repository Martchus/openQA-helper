#!/bin/bash -e

# define function to clone repo and add fork
function clone_repo() {
    local repo_name=${1}
    local repo_as=${2:-$repo_name}
    local repo_url="https://github.com/os-autoinst/$repo_name"

    if [[ -d $repo_as ]]; then
        echo "Skipping $repo_name; already exists."
        return 0
    fi

    git clone "$repo_url" "$repo_as"
    pushd "$repo_as"
    git remote add "$gh_user" "git@github.com:$gh_user/$repo_name.git"
    git remote update
    popd
}
