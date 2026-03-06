#!/bin/bash

# Termux/Linux Mobile continuous updater script
# Make sure to run this inside the cloned repository directory.

echo "============================================="
echo "Starting TCL Leaderboard mobile updater..."
echo "Press Ctrl+C to stop."
echo "============================================="

# Ensure basic git config is set so commits don't fail on a fresh clone
git config --global user.name 'mobile-updater'
git config --global user.email 'mobile-updater@localhost'

# Load or prompt for Discord Webhook URL
if [ -f .env ]; then
  source .env
fi

if [ -z "$DISCORD_WEBHOOK_URL" ]; then
  echo ""
  echo "⚠️ Discord Webhook URL not found."
  read -p "Please paste your Discord Webhook URL here: " DISCORD_WEBHOOK_URL
  # Initialize the .env file with the webhook URL
  echo "export DISCORD_WEBHOOK_URL='$DISCORD_WEBHOOK_URL'" > .env
  echo "✅ Webhook URL saved to .env file."
  echo ""
fi

if [ -z "$FACEIT_SEASON_ID" ]; then
  echo ""
  echo "⚠️ FaceIT Season ID not set."
  read -p "Please enter the current FaceIT Season ID (e.g. 29): " FACEIT_SEASON_ID
  # Append the season ID to the existing .env file
  echo "export FACEIT_SEASON_ID='$FACEIT_SEASON_ID'" >> .env
  echo "✅ Season ID saved to .env file."
  echo ""
fi

POLL_INTERVAL=30

while true; do
  echo "--- Poll at $(date) ---"
  
  # Fetch data and update discord (if DISCORD_WEBHOOK_URL is set in env)
  python3 scripts/fetch_data.py
  python3 scripts/discord_webhook.py
  
  git add docs/data/
  if ! git diff --quiet || ! git diff --staged --quiet; then
    echo "Changes detected, committing and pushing..."
    git commit -m "Auto-update leaderboard data (Mobile)"
    
    # Robust pull to avoid conflicts if GitHub Action is running simultaneously
    if ! git pull --rebase origin main; then
      echo "Git rebase conflict detected! Resetting to remote main..."
      git rebase --abort
      git reset --hard origin/main
      echo "Skipping push for this cycle."
    else
      git push origin main
    fi
  else
    echo "No changes."
  fi
  
  sleep $POLL_INTERVAL
done
