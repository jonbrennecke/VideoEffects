#!/usr/bin/env zsh
version="0.0.11"

git commit --allow-empty -m "v$version"

if [ -z "$(git status --porcelain)" ]; then 
  git tag "v$version"
  git push origin master
  git push origin master --tags
  pod repo push private-pod-specs Captions.podspec --allow-warnings  
else 
  echo "Error: Git has uncommitted changes."
  exit 1
fi
