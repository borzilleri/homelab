#!/bin/bash
# Keep an SMB share mounted. Intended to run periodically from launchd.
#
# Usage: volume-mount.sh smb://user@host/share
#
# Pushover credentials are read from ~/.config/volume-mount/config.env (see
# config.env.example).
#
# Expects a file named .liveness.txt at the root of the share, and the share's
# password stored in the login keychain (mount once via Finder's Connect to
# Server and tick "Remember this password").
#
# If the share can't be mounted, or is mounted but the liveness file is
# missing, a Pushover notification is sent. Only one notification is sent per
# outage, and another is sent once the share is mounted again.
set -u

SMB_URL="${1:?usage: $0 smb://user@host/share}"
CONFIG_FILE="$HOME/.config/volume-mount/config.env"
STATE_DIR="$HOME/.local/state/volume-mount"
LIVENESS_FILE=".liveness.txt"
MOUNT_TIMEOUT=10
MOUNT_ATTEMPTS=3

log() {
	echo "$(date '+%Y-%m-%d %H:%M:%S') $*"
}

PUSHOVER_TOKEN="" PUSHOVER_USER=""
# shellcheck source=/dev/null
[ -r "$CONFIG_FILE" ] && . "$CONFIG_FILE"

# host/share, without scheme or user
HOST_SHARE="${SMB_URL#*://}"
HOST_SHARE="${HOST_SHARE#*@}"
# One failure marker per share, e.g. host_share.failed
FAILED_MARKER="$STATE_DIR/$(printf '%s' "$HOST_SHARE" | sed 's/[^A-Za-z0-9._-]/_/g').failed"

# Print the local mount point of SMB_URL, or nothing if it isn't mounted.
# mount(8) lists SMB shares as "//user@host/share on /Volumes/share (smbfs, ...)".
find_mount_point() {
	mount | sed -n "s|^//\([^@]*@\)\{0,1\}${HOST_SHARE} on \(.*\) (smbfs.*|\2|p" | head -n 1
}

# Usage: is_live MOUNT_POINT
is_live() {
	[ -n "$1" ] && [ -f "$1/$LIVENESS_FILE" ]
}

# Run a command, killing it if it runs longer than $1 seconds.
run_with_timeout() {
	local secs="$1"
	shift
	"$@" &
	local pid=$!
	(sleep "$secs" && kill "$pid" 2>/dev/null) &
	local watcher=$!
	wait "$pid"
	local status=$?
	kill "$watcher" 2>/dev/null
	wait "$watcher" 2>/dev/null
	return "$status"
}

pushover() {
	local title="$1" message="$2"
	if [ -z "$PUSHOVER_TOKEN" ] || [ -z "$PUSHOVER_USER" ]; then
		log "cannot send notification: PUSHOVER_TOKEN and PUSHOVER_USER must be set in $CONFIG_FILE"
		return 1
	fi
	curl -fsS --max-time 15 -o /dev/null \
		--form-string "token=$PUSHOVER_TOKEN" \
		--form-string "user=$PUSHOVER_USER" \
		--form-string "title=$title" \
		--form-string "message=$message" \
		https://api.pushover.net/1/messages.json \
		|| { log "failed to send Pushover notification"; return 1; }
}

on_success() {
	if [ -e "$FAILED_MARKER" ]; then
		log "$SMB_URL is mounted again"
		pushover "Volume mounted" "$SMB_URL on $(hostname -s) is mounted again." && rm -f "$FAILED_MARKER"
	fi
	exit 0
}

# Usage: on_failure REASON
on_failure() {
	log "$1"
	if [ ! -e "$FAILED_MARKER" ]; then
		mkdir -p "$STATE_DIR"
		pushover "Volume mount failed" "$1 (on $(hostname -s))" && touch "$FAILED_MARKER"
	fi
	exit 1
}

mount_point="$(find_mount_point)"
if [ -n "$mount_point" ]; then
	is_live "$mount_point" && on_success
	# Mounted but the liveness file is missing; remounting won't help.
	on_failure "$SMB_URL is mounted at $mount_point but $LIVENESS_FILE is missing"
fi

attempt=1
while [ "$attempt" -le "$MOUNT_ATTEMPTS" ]; do
	log "mounting $SMB_URL (attempt $attempt/$MOUNT_ATTEMPTS)"
	if run_with_timeout "$MOUNT_TIMEOUT" osascript -e "mount volume \"$SMB_URL\"" >/dev/null; then
		mount_point="$(find_mount_point)"
		if is_live "$mount_point"; then
			log "mounted $SMB_URL at $mount_point"
			on_success
		fi
	fi
	attempt=$((attempt + 1))
done

on_failure "Could not mount $SMB_URL after $MOUNT_ATTEMPTS attempts"
