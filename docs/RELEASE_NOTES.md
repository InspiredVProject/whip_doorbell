# Vista Home 2.0.7 — WHIP Doorbell

Bring a smart video doorbell experience to your WHIP roleplay server. Install a custom doorbell, see real in-game camera snapshots on the Vista Home app, receive visitor and motion alerts, and answer visitors using genuine two-way WHIP voice communication.

### Highlights
- Three custom doorbell finishes with illuminated variants.
- Native WHIP inventory and interaction integration.
- Redesigned Vista Home dashboard, device settings and filterable event history.
- Saved camera snapshots using WHIP's native capture API.
- Automatic snapshots every 5–10 minutes while the app is open and eligible.
- Real two-way voice intercom, household sharing, chime and siren.
- In-game configuration via `/whip` and size-limited image transfers.

### Requirements
`whip_core` (with native screenshot API), `whip_phone` and `whip_voice`. No screenshot-basic or separate inventory framework required.

### Install / upgrade
Extract the resource as `whip_doorbell`, ensure it after its WHIP dependencies and give yourself the `vista_doorbell` item. Existing installations must preserve `data/doorbells.json`. Read the README for full instructions.

### Known limitations
Live View is rendered behind the phone; saved previews are displayed inside the app. Automatic screenshots require an active, eligible client with the app open. Event history is not a video archive. Remote streaming depends on FiveM and routing buckets. Test on your WHIP server before deploying to production.

Repository documentation and packaging have been improved without changing the 2.0.7 gameplay code.
