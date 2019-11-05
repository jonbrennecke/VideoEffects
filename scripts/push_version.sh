
#!/usr/bin/env zsh
version=$(cat version.txt)
if [ -z "$(git status --porcelain)" ]; then 
  git commit --allow-empty -m "v$version"
  git tag "v$version"
else 
  echo "Error: Git has uncommitted changes."
  exit 1
fi
