#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_REPO="${1:-${UPSTREAM_REPO:-}}"
GH_TOKEN="${GH_TOKEN:-}"

if [[ -z "$UPSTREAM_REPO" || -z "$GH_TOKEN" ]]; then
  echo "Usage: GH_TOKEN=... ./sync_all_branches.sh YoYoGames/GameMaker-Manual"
  exit 1
fi

# Git identity
git config --global user.name "github-actions"
git config --global user.email "github-actions@users.noreply.github.com"

# Add upstream remote if not present
if ! git remote | grep -q "^upstream$"; then
  echo "Adding upstream remote..."
  git remote add upstream "https://x-access-token:${GH_TOKEN}@github.com/${UPSTREAM_REPO}.git"
fi

echo "Fetching upstream..."
git fetch upstream

# Get local branches that also exist upstream
common_branches=$(git branch -r | grep 'origin/' | sed 's|origin/||' | while read -r branch; do
  if git ls-remote --exit-code --heads upstream "$branch" &>/dev/null; then
    echo "$branch"
  fi
done)

for branch in $common_branches; do
  echo "====== Syncing branch: $branch ======"

  # Check out the branch
  git checkout "$branch"

  # Merge from upstream
  if git merge -X ours --allow-unrelated-histories "upstream/$branch" -m "Merge upstream/$branch with 'ours' strategy"; then
    echo "Merge successful on $branch"
  else
    echo "Merge conflict on $branch, trying auto-resolution..."
    UNMERGED_FILES=$(git diff --name-only --diff-filter=U)
    if [[ -n "$UNMERGED_FILES" ]]; then
      echo "$UNMERGED_FILES" | xargs git rm -f
      git commit -am "Auto-resolved conflicts in $branch using ours strategy"
    fi
  fi

  # Only push if there are actual changes
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "Pushing updates to origin/$branch"
    git push origin "$branch"
  else
    echo "No changes to push on $branch"
  fi

  echo ""
done

echo "✅ All branches synced with upstream."
