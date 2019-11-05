
#!/usr/bin/env zsh
version=$(cat version.txt)
if [ -z "$(git status --porcelain)" ]; then 
  git commit --allow-empty -m "v$version"
  git tag "v$version"
  git push origin master
  git push origin master --tags
  pod repo push private-pod-specs Captions.podspec --allow-warnings  
else 
  echo "Error: Git has uncommitted changes."
  exit 1
fi
