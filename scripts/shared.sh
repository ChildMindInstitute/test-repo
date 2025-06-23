message() {
  echo -e "\n######################################################################"
  echo "# $1"
  echo "######################################################################"
}

# Get the next release version
getReleaseVersion() {
  # 1. Create array based on LATEST_TAG
#  LATEST_TAG=$(git describe --tags "$(git rev-list --tags --max-count=1)") # gets tags across all branches, not just the current branch
  LATEST_TAG=$(gh release list --exclude-drafts --exclude-pre-releases --json tagName,isLatest | jq -r '.[] | select(.isLatest == true) | .tagName')
  TAG_LIST=($(echo "$LATEST_TAG" | tr '.' ' '))

  echo $LATEST_TAG

  # 2. Exit if invalid version
  [[ "${#TAG_LIST[@]}" -ne 3 ]] && echo "$LATEST_TAG is not a valid version" && exit 1

  # 3. Calculate release version
  V_DATE=$(date +%Y)
  V_MONTH=$(date +%m)
  LAST_MONTH=${TAG_LIST[1]}
#  LAST_MONTH="06"
  V_PATCH=0
  [[ LAST_MONTH -eq V_MONTH ]] && V_PATCH=$(( TAG_LIST[2] + 1 ))

  export RELEASE_VERSION=${V_DATE}.${V_MONTH}.${V_PATCH}
  PREVIOUS_VERSION="$LATEST_TAG"
  export PREVIOUS_VERSION
}
