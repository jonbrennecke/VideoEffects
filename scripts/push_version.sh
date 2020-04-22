#!/usr/bin/env zsh
version=$(ruby -e "$(head -n 1 VideoEffects.podspec); puts(version.strip);")

git commit -a --allow-empty -m "v$version"

if [ -z "$(git status --porcelain)" ]; then 
  git tag "v$version"
  git push origin master
  git push origin master --tags
  pod repo push private-pod-specs VideoEffects.podspec --allow-warnings  
else 
  echo "Error: Git has uncommitted changes."
  exit 1
fi
