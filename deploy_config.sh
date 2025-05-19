#!/bin/bash

# This script deploys files to a remote server using rsync over SSH.
# It copies all files from the directory where the script is executed (not where it resides)
# to the remote server directory defined in deploy_config.env.
# The deploy_config.env file must be located in the same directory as this script,
# and must define the following variables:
#   - REMOTE_USER: SSH user for the remote server
#   - REMOTE_HOST: Hostname or IP of the remote server
#   - SSH_KEY: Path to the SSH private key
#   - REMOTE_DIR: Destination directory on the server

set -e

# Load deployment configuration from the same directory as the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/deploy_config.env"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Configuration file '$CONFIG_FILE' not found."
  exit 1
fi

source "$CONFIG_FILE"

: "${REMOTE_USER:?Must set REMOTE_USER}"
: "${REMOTE_HOST:?Must set REMOTE_HOST}"
: "${SSH_KEY:?Must set SSH_KEY}"
: "${REMOTE_DIR:?Must set REMOTE_DIR}"

# 1. Create the remote directory with proper ownership
echo "🛠 Creating target directory on the server..."
ssh -i "$SSH_KEY" $REMOTE_USER@$REMOTE_HOST "sudo mkdir -p $REMOTE_DIR && sudo chown $REMOTE_USER:$REMOTE_USER $REMOTE_DIR"

# 2. Clean existing contents (but keep the directory)
echo "🧹 Cleaning up existing files in target directory..."
ssh -i "$SSH_KEY" $REMOTE_USER@$REMOTE_HOST "find $REMOTE_DIR -mindepth 1 -delete"

 # 3. Upload all project files from the current directory to the server, excluding certain files
echo "⬆️  Uploading files to the server..."
rsync -avz -e "ssh -i $SSH_KEY" \
  --exclude '**/.DS_Store' \
  --exclude '.git/' \
  "$(pwd)/" $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR

echo "✅ Upload complete."