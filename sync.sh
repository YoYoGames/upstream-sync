#!/bin/bash
set -ex

UPSTREAM_REPO="$1"
GH_TOKEN="$2"

if [[ -z "$UPSTREAM_REPO" || -z "$GH_TOKEN" ]]; then
    echo "Usage: sync_upstream.sh <upstream_repo> <github_token>"
    exit 1
fi

echo "Configuring Git user..."
git config --global user.name "ksuchitra532"
git config --global user.email "ksuchitra532@gmail.com"

echo "Checking Git version..."
git --version

echo "Adding upstream remote and fetching all branches..."
git remote add upstream "https://x-access-token:${GH_TOKEN}@github.com/${UPSTREAM_REPO}.git"
git fetch upstream --tags

echo "Merging upstream changes for all branches..."
for branch in $(git branch -r | grep 'upstream/' | grep -v 'HEAD' | sed 's/upstream\///'); do
    echo "Syncing branch: $branch"
    
    if ! git show-ref --verify --quiet refs/heads/$branch; then
        git checkout -b $branch upstream/$branch
    else
        git checkout $branch
        git fetch upstream $branch
        git pull --rebase upstream $branch || {
            echo "Merge conflict or non-fast-forward merge for branch $branch"
            exit 1
        }
    fi

    LOCAL_SHA=$(git rev-parse HEAD)
    REMOTE_SHA=$(git ls-remote "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" refs/heads/$branch | awk '{print $1}')

    if [[ "$LOCAL_SHA" == "$REMOTE_SHA" ]]; then
        echo "No changes to push for branch $branch, skipping."
        continue
    fi

    echo "Pushing updates to origin for branch $branch..."
    git push --force "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" $branch
done