# Data and privacy

`data/doorbells.json` is server-side runtime state. It contains device IDs, coordinates, headings, routing buckets, WHIP character IDs, owner/shared-character names, alert history and the latest camera snapshot (a base64 data URL). Visitor names are hidden in ring/motion history by default, but owner and shared-user names are stored for device management.

- The release includes only an empty `data/` directory marker; the live JSON is created by the resource when saving.
- Back up the JSON outside your Git repository before updating. Restore it only to the server it belongs to. Do not commit it, upload it to GitHub or share it in bug reports.
- `.gitignore` protects new untracked runtime files, not files already committed. Remove any accidentally tracked live data from the index and address exposure in repository history before sharing.
- Device access and ownership are checked server-side. Saved snapshots are requested separately from device metadata and transmitted using size-limited latent network events.
- Only the latest preview is kept per device; the event history has a configurable count limit. There is no audio recording or video archive in this resource. The voice intercom connects two participants in a WHIP voice line.
- Use the doorbell system for in-game roleplay and make players aware of simulated camera and voice interactions according to your server rules.

The resource does not migrate legacy ESX/QBCore ownership records. Installed devices use WHIP character IDs and stored routing buckets. Temporary instance identifiers may not remain valid after a restart.
