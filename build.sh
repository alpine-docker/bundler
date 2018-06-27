#!/usr/bin/env bash

# Prerequisite
# Make sure you set secret enviroment variables: DOCKER_USERNAME and  DOCKER_PASSWORD in Travis CI

set -ex

Usage() {
  echo "$0 [rebuild]"
}

image="alpine/bundle"
repo="ruby/ruby"

latest=`curl -s https://api.github.com/repos/${repo}/tags |jq -rS ".[].name"|awk -F "_" '{if (NF == 3 && /^v/) {gsub(/^v/,"");gsub(/_/,".");print}}' |head -1`
sum=0
echo "Lastest release is: ${latest}"

tags=`curl -s https://hub.docker.com/v2/repositories/${image}/tags/ |jq -r .results[].name`

for i in ${tags}
do
  if [ ${i} == ${latest} ];then
    sum=$((sum+1))
  fi
done

if [[ ( $sum -ne 1 ) || ( $1 == "rebuild" ) ]];then
  sed "s/VERSION/${latest}/" Dockerfile.template > Dockerfile
  docker build --no-cache -t ${image}:${latest} .
  docker tag ${image}:${latest} ${image}:latest

  if [[ "$TRAVIS_BRANCH" == "master" ]]; then
    docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
    docker push ${image}:${latest}
    docker push ${image}:latest
  fi

fi
