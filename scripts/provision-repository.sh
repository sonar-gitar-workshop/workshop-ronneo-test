#!/usr/bin/env bash
set -euo pipefail

target_repo="${1:-}"

if [[ ! "$target_repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "Usage: $0 OWNER/REPOSITORY" >&2
  exit 2
fi

required_branches=(
  main
  part-2-price-override
  part-3-context-ingestion
  part-4-ci-failure
)

for branch in "${required_branches[@]}"; do
  if ! git show-ref --verify --quiet "refs/heads/$branch"; then
    if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
      git branch "$branch" "origin/$branch" >/dev/null
    else
      echo "Missing branch: $branch" >&2
      exit 1
    fi
  fi
done

if gh repo view "$target_repo" >/dev/null 2>&1; then
  echo "Refusing to overwrite existing repository: $target_repo" >&2
  exit 1
fi

gh repo create "$target_repo" \
  --private \
  --description "Provisioned Gitar workshop repository"

git push "https://github.com/${target_repo}.git" main

gh api --method PATCH "repos/$target_repo" \
  -f default_branch=main \
  -F allow_auto_merge=true >/dev/null

for attempt in {1..30}; do
  if gh api "repos/$target_repo/actions/workflows/test.yml" >/dev/null 2>&1; then
    break
  fi
  if [[ "$attempt" -eq 30 ]]; then
    echo "GitHub did not register the Test workflow" >&2
    exit 1
  fi
  sleep 2
done

git push "https://github.com/${target_repo}.git" "${required_branches[@]:1}"

gh label create documentation \
  --repo "$target_repo" \
  --color 0075ca \
  --description "Improvements or additions to documentation" \
  --force >/dev/null

gh api --method PUT "repos/$target_repo/branches/main/protection" --input - <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["test"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": false,
  "lock_branch": false,
  "allow_fork_syncing": false
}
JSON

echo "Provisioned https://github.com/$target_repo"
echo "Next: connect the repository and enable auto-approve in Gitar Settings > Configuration."
