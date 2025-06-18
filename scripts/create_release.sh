#!/bin/bash
set -e

message() {
  echo -e "\n######################################################################"
  echo "# $1"
  echo "######################################################################"
}

getReleaseVersion() {
  # 1. Create array based on LATEST_TAG
#  LATEST_TAG=$(git describe --tags "$(git rev-list --tags --max-count=1)") # gets tags across all branches, not just the current branch
  LATEST_TAG=$(gh release list --exclude-drafts --exclude-pre-releases --json tagName,isLatest | jq -r '.[] | select(.isLatest == true) | .tagName')
  TAG_LIST=($(echo "$LATEST_TAG" | tr '.' ' '))

  # 2. Exit if invalid version
  [[ "${#TAG_LIST[@]}" -ne 3 ]] && echo "$LATEST_TAG is not a valid version" && exit 1

  # 3. Calculate release version
  V_DATE=$(date +%Y)
  V_MONTH=$(date +%m)
  LAST_MONTH=${TAG_LIST[1]}
#  LAST_MONTH="06"
  V_PATCH=0
  [[ LAST_MONTH -eq V_MONTH ]] && V_PATCH=$(( TAG_LIST[2] + 1 ))

  RELEASE_VERSION=${V_DATE}.${V_MONTH}.${V_PATCH}
}

message ">>> Starting release"

[[ ! -x "$(command -v gh)" ]] && echo "gh not found, you need to install github CLI" && exit 1

gh auth status

# 1. Make sure branch is set to develop
[[ $(git rev-parse --abbrev-ref HEAD) != "develop" ]] && echo "ERROR: Checkout to develop" && exit 1

# 2. Make sure branch is clean TODO uncomment
#[[ $(git status --porcelain) ]] && echo "ERROR: The branch is not clean, commit your changes before creating the release" && exit 1

message ">>> Pulling develop"
git pull origin develop ##
message ">>> Pulling tags"
git fetch --prune --prune-tags origin

getReleaseVersion

message ">>> Release: $RELEASE_VERSION"

# 5. Start release
read -r -p "Last release version was '$LATEST_TAG', do you want to create '$RELEASE_VERSION' [Y/n]:  " RESPONSE
#if [[ $RESPONSE =~ ^([yY][eE][sS]|[yY])$ ]]; then
#
#  BRANCH_NAME="release/$RELEASE_VERSION"
#  message ">>>>> Creating branch '$BRANCH_NAME' from develop..."
#
#  git checkout -b "$BRANCH_NAME" develop
#  git push origin "$BRANCH_NAME"
#  gh pr create --base main --head "$BRANCH_NAME" --title "Release - $RELEASE_VERSION" --fill
#
#else
#
#    message "Action cancelled exiting..."
#    exit 1
#
#fi