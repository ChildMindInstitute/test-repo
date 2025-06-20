#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. ${SCRIPT_DIR}/shared.sh

#export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
#  --color=fg:#d0d0d0,fg+:#d0d0d0,bg:#121212,bg+:#262626
#  --color=hl:#5f87af,hl+:#5fd7ff,info:#afaf87,marker:#87ff00
#  --color=prompt:#d7005f,spinner:#af5fff,pointer:#af5fff,header:#87afaf
#  --color=border:#262626,label:#aeaeae,query:#d9d9d9
#  --border="rounded" --border-label="Select RC" --border-label-pos="3" --preview-window="border-rounded"
#  --prompt="> " --marker=">" --pointer="◆" --separator="─"
#  --scrollbar="│"'

# morhetz/gruvbox
#export FZF_DEFAULT_OPTS='--color=bg+:#3c3836,bg:#32302f,spinner:#fb4934,hl:#928374,fg:#ebdbb2,header:#928374,info:#8ec07c,pointer:#fb4934,marker:#fb4934,fg+:#ebdbb2,prompt:#fb4934,hl+:#fb4934'
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=fg:#d0d0d0,fg+:#d0d0d0,bg:#4b4747,bg+:#6a6666
  --color=hl:#5f87af,hl+:#5fd7ff,info:#afaf87,marker:#87ff00
  --color=prompt:#d7005f,spinner:#af5fff,pointer:#af5fff,header:#87afaf
  --color=border:#262626,label:#aeaeae,query:#d9d9d9
  --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="➡️ "
  --marker="✦" --pointer="→" --separator="─" --scrollbar="│" --height="25%"'

getPreviousRCs() {
  # 1. Create array based on LATEST_TAG
  PREVIOUS_RCS=$(gh release list --json tagName,isLatest | jq -r '[.[] | select(.isLatest == false and (.tagName | test("rc"))) | .tagName] | join(" ")')
  export PREVIOUS_RCS
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
getPreviousRCs

message ">>> Release: $RELEASE_VERSION"

BASED_RC=""
BASED_MESSAGE=""
read -r -p "Do you want to promote an RC to a release?' [Y/n]:  " RESPONSE
if [[ $RESPONSE =~ ^([yY][eE][sS]|[yY])$ ]]; then
  BASED_RC=$(echo "$PREVIOUS_RCS" | tr ' ' '\n' | fzf)
  BASED_MESSAGE=" based on RC'${BASED_RC}'"
fi

# 5. Start release
read -r -p "Last release version was '$LATEST_TAG', do you want to create '$RELEASE_VERSION' ${BASED_MESSAGE} [Y/n]:  " RESPONSE
if [[ $RESPONSE =~ ^([yY][eE][sS]|[yY])$ ]]; then

  BRANCH_NAME="release/$RELEASE_VERSION"
  message ">>>>> Creating branch '$BRANCH_NAME' from develop..."

  git checkout -b "$BRANCH_NAME" develop
  git push origin "$BRANCH_NAME"
  PR_NUMBER=$(gh pr create --base main --head "$BRANCH_NAME" --title "Release - $RELEASE_VERSION" --fill  --fill --json number -q '.number')

  # 5a. Leave a comment that the GH action can read so it knows if it needs to do a build
  # or simply promote an existing RC.
  if [[ -z $BASED_RC ]]; then
    gh pr comment "${PR_NUMBER}" --body "Upstream RC: ${BASED_RC}"
  fi
else
    message "Action cancelled exiting..."
    exit 1
fi



