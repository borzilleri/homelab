# volume-mount

Keeps an SMB share mounted on macOS. Uses a launchd agent that runs regularly 
(every 60s by default) and executes a script to check for and mount a share.
Notifies on failure via Pushover.

## Setup

1. Mount the share once with Finder → Go → Connect to Server (⌘K), and save
   the password to the keychain.
2. Create an empty `.liveness.txt` file at the root of the share.
3. Install the script:
   ```sh
   mkdir -p ~/.local/bin
   cp volume-mount.sh ~/.local/bin/
   ```
4. Configure Pushover credentials:
   ```sh
   mkdir -p ~/.config/volume-mount
   cp config.env.example ~/.config/volume-mount/config.env
   chmod 600 ~/.config/volume-mount/config.env
   # edit in PUSHOVER_TOKEN and PUSHOVER_USER
   ```
5. Edit `local.volume-mount.plist` and replace `smb://USER@HOST/SHARE` with the
   share URL. Then load the agent:
   ```sh
   cp local.volume-mount.plist ~/Library/LaunchAgents/
   launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.volume-mount.plist
   ```

To keep more than one share mounted, copy the plist and give each copy its own
`Label` and share URL.

Logs go to `~/Library/Logs/volume-mount.log`. Failure markers (used to send only
one notification per outage) are stored per share in
`~/.local/state/volume-mount/`.
