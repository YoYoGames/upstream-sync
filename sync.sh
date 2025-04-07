#!/usr/bin/env bash
set -euo pipefail

# Usage: ./merge_upstream.sh <upstream_repo>
# Example: ./merge_upstream.sh YoYoGames/GameMaker-Manual

UPSTREAM_REPO="${1:-${UPSTREAM_REPO:-}}"
GH_TOKEN="${GH_TOKEN:-}"

if [[ -z "$UPSTREAM_REPO" || -z "$GH_TOKEN" ]]; then
  echo "Usage: GH_TOKEN=... ./merge_upstream.sh YoYoGames/GameMaker-Manual"
  exit 1
fi

# Configure Git user
git config --global user.name "github-actions"
git config --global user.email "github-actions@users.noreply.github.com"

# Ensure we're in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git repository."
  exit 1
fi

# Add upstream remote if not already added
if ! git remote | grep -q "^upstream$"; then
  echo "Adding upstream remote..."
  git remote add upstream "https://x-access-token:${GH_TOKEN}@github.com/${UPSTREAM_REPO}.git"
fi

echo "Fetching upstream..."
git fetch upstream

echo "Merging upstream/develop with 'ours' strategy..."
if ! git merge -X ours upstream/develop; then
  echo "Merge conflict detected. Attempting to resolve..."
  git diff --name-only --diff-filter=U | xargs git rm -f || true
  git commit -am "Resolved merge conflicts using ours strategy"
fi

echo "Pushing changes..."
git push origin HEAD

echo "Merge and push completed successfully."
