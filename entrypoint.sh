#!/bin/sh -l

set -u

cd /github/workspace || exit 1

if [ -z "${GITHUB_TOKEN}" ]; then
  echo "The GITHUB_TOKEN environment variable is not defined."
  exit 1
fi

BRANCH="${1}"
PRODUCTION="${2}"

git config --global --add safe.directory /github/workspace
git fetch --depth=1 origin +refs/tags/*:refs/tags/*

CURRENT_YEAR_MONTH=$(date "+%Y.%m")

LATEST_PROD_RELEASE=$(git tag --sort=v:refname | grep "^20[^\-]*$" | tail -n 1)
LATEST_PROD_YEAR_MONTH=$(echo "${LATEST_PROD_RELEASE}" | awk '{ string=substr($0, 1, 7); print string; }')
LATEST_PROD_MINOR="$(echo "${LATEST_PROD_RELEASE}" | awk '{ string=substr($0, 9); print string; }')"

if [ "$PRODUCTION" == "true" ] || [ "$PRODUCTION" == true ]; then
  NEXT_PROD_MINOR=$(echo $((LATEST_PROD_MINOR + 1)))
  NEXT_RELEASE=${CURRENT_YEAR_MONTH}.${NEXT_PROD_MINOR}
else
  LATEST_BETA_RELEASE=$(git tag --sort=v:refname | grep -Eo "[^[:space:]]+-[^[:space:]]+" | tail -n 1)
  LATEST_BETA_YEAR_MONTH=$(echo "${LATEST_BETA_RELEASE}" | awk '{ string=substr($0, 1, 7); print string; }')
  INDEX=$(expr index "$LATEST_BETA_RELEASE" "-")

  LATEST_BETA_MINOR="$(echo "${LATEST_BETA_RELEASE}" | awk -v offset=$((INDEX - 9)) '{ string=substr($0, 9, offset); print string; }')"
  LATEST_BETA_ID="$(echo "${LATEST_BETA_RELEASE}" | awk -v l=$((INDEX + 1)) '{ string=substr($0, l); print string; }')"

  NEXT_BETA_ID=$([ "${LATEST_PROD_MINOR}" == "${LATEST_BETA_MINOR}" ] && echo $((LATEST_BETA_ID + 1)) || echo 1)
  NEXT_RELEASE=${CURRENT_YEAR_MONTH}.${LATEST_PROD_MINOR:-1}-${NEXT_BETA_ID:-1}
fi

JSON_STRING=$(jq -n \
  --arg tn "$NEXT_RELEASE" \
  --arg tc "$BRANCH" \
  '{tag_name: $tn, target_commitish: $tc}')
echo "${JSON_STRING}"
OUTPUT=$(curl -s --data "${JSON_STRING}" -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases")
echo "${OUTPUT}" | jq

echo "release=${NEXT_RELEASE}" >>$GITHUB_OUTPUT
