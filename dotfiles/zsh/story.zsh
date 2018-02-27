function story() {
  if [ -n "$TRACKER_API_TOKEN" ]; then
    STORY_TITLE=" $(curl -s -H "X-TrackerToken: $TRACKER_API_TOKEN" \
      "https://www.pivotaltracker.com/services/v5/projects/$TRACKER_PROJECT/stories/${1/\#/}" \
      | jq -r .name)"
  else
    STORY_TITLE=''
  fi
  printf "\n\n[$1]$STORY_TITLE" > ~/.git-tracker-story
}
