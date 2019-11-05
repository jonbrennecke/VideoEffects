
#!/usr/bin/env zsh
if [ -z "$(git status --porcelain)" ]; then 
  git commit -am "v$1"
  git tag "v$1"
else 
  echo "Error: Git has uncommitted changes."
  exit 1
fi