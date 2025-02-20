#!/bin/sh

# Props to Aaron Bauman for writing the original script.
# https://gist.github.com/aaronbauman/f50cc691eb3ed60a358c

# Settings
terminus='terminus'
projects="$HOME/Projects"
directoryName='sequelpro-pantheon'
pantheonEmail=''
pantheonPassword=''

# You has terminus?
if ! type $terminus >/dev/null 2>&1; then
  echo
  echo 'You are missing the awesomeness.'
  echo
  echo 'Install Terminus to use this script.'
  echo 'https://pantheon.io/docs/terminus/install'
  exit 0
fi

if [ $# -lt 1 ]
then
  echo "Usage: $0 @pantheon-alias"
  exit 1
fi

# Authenticate with Terminus
$terminus auth:login --email $pantheonEmail

# Path to pantheon.spf file.
# Should be located within the same directory as this file.
TEMPLATE="$projects/$directoryName/pantheon.spf"

# Temporary write path.
TMP_SPF='/tmp/tmp.spf'

# Update aliases
$terminus aliases

# Database Creds
DATABASE=$($terminus connection:info ${1:1} --field=mysql_database)
HOST=$($terminus connection:info ${1:1} --field=mysql_host)
PORT=$($terminus connection:info ${1:1} --field=mysql_port)
PASSWORD=$($terminus connection:info ${1:1} --field=mysql_password)
USER=$($terminus connection:info ${1:1} --field=mysql_username)

# SSH Creds
SSH_HOST=$($terminus connection:info ${1:1} --field=sftp_host)
SSH_USER=$($terminus connection:info ${1:1} --field=sftp_username)
SSH_PASSWORD=$pantheonPassword
SSH_PORT='2222'

# Pantheon sandbox/dev/test environments goto sleep when they are not visited.
# Incase the environment is asleep, we wake it up with terminus.
# Otherwise you will get a timeout error connecting to unvisited, not-live databases.
if [[ $env != 'live' ]]; then
  echo
  echo 'Connecting, waking up environment.'
  echo
  $terminus env:wake ${1:1}
fi

# Echo variables into template.

# This is for Sequel Pro:
eval "echo \"$(< $TEMPLATE)\""
# For some reason, Sequel Pro or Open do not behave the same way given the -f 
# flag compared to opening a file from file system. So, we write to a tmp file.
eval "echo \"$(< $TEMPLATE)\"" > $TMP_SPF

open $TMP_SPF