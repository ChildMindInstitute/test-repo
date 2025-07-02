#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "${SCRIPT_DIR}"/shared.sh

getRCVersion() {
  NEXT_RELEASE=$1
  # 1. Create array based on LATEST_TAG
  LATEST_TAG=$(gh release list --json tagName,isLatest | jq -r '[.[] | select(.isLatest == false)][0].tagName')

  NEXT_RELEASE="2025.06.0"
  LATEST_TAG="2025.06.0-rc2"

  RC_TAG=($(echo "${LATEST_TAG}" | tr '-' ' '))
  NEXT_RC=${RC_TAG[0]}

  echo "${NEXT_RC} == ${NEXT_RELEASE}"

  # If the last tag was an RC, increment the tag
  V_RC="1"
  if [ "${NEXT_RC}" == "${NEXT_RELEASE}" ] && [ "${RC_TAG[1]+set}" ]; then
    OLD_RC=$(echo "${RC_TAG[1]}" | grep -o '[0-9]\+$')
    V_RC=$((  OLD_RC + 1 ))
  fi

  export PREVIOUS_RC=${LATEST_TAG}
  export RC_VERSION=${NEXT_RELEASE}-rc${V_RC}
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

# Check if and RC is necessary
COMMITS=$(git rev-list --count develop ^main)
if [ "$COMMITS" -eq 0 ]; then
  message ">>> There are no new commits in this branch.  RC not needed."
  exit 0
fi

getReleaseVersion
getRCVersion "${RELEASE_VERSION}"

message ">>> Release: ${RC_VERSION}"

# 5. Start release
read -r -p "Next release version is '$RELEASE_VERSION', last RC was '$PREVIOUS_RC', do you want to create '$RC_VERSION' [Y/n]:  " RESPONSE
if [[ $RESPONSE =~ ^([yY][eE][sS]|[yY])$ ]]; then

  RELEASE_BRANCH="release/${RELEASE_VERSION}"
  RC_TAG="release/${RC_VERSION}"

  # Check for the release branch
#  if git ls-remote --heads origin "${RELEASE_BRANCH}" | grep -q .; then
#    message ">>> Release Branch '$RELEASE_VERSION' already exists, skipping creation..."
#  else
#    message ">>>>> Creating branch '$RELEASE_BRANCH' from develop..."
#    git checkout -b "$RELEASE_BRANCH" develop
#    git push origin "$RELEASE_BRANCH"
#  fi

  # Creation of the RC tag triggers the build and will then create a release
  message ">>> Creating RC tag"
  git tag "${RC_TAG}"
  git push origin refs/tags/"${RC_TAG}"

#  message ">>> Creating RC Pull Request"
#  gh pr create --base main --head "${RELEASE_BRANCH}" --title "Release - $RC_VERSION"

else
    message "Action cancelled exiting..."
    exit 1
fi