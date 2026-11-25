# Changelog

## 2.0.7 — Camera-first app redesign
- Vista-branded dashboard, device management, camera controls and event history pages.
- Device/event filters, relative timestamps, compact snapshot control and bottom navigation.
- Retained the existing screenshot, intercom and automatic refresh behaviour.

## 2.0.6 — Automatic previews
- Configurable 5–10 minute interval while the app is open; stale preview checks on reopen.
- Sequential capture, deferred busy states and automatic retry backoff.

## 2.0.5 — Camera preview reliability
- Wait for the capture camera, restore the phone camera, show the image locally and save it.
- Inline capture progress and errors; bounded latent transfers.

## 2.0.4 — Preview controls
- More visible refresh button; versioned phone module filename.

## 2.0.3 — Native WHIP screenshots
- Replaced screenshot-basic with WHIP's native screenshot API.
- Camera preview cards and separate size-limited image transport.

## 2.0.2 — Saved previews
- Introduced preview image and timestamp UI; initially used screenshot-basic (superseded).

## 2.0.1 — Inventory fix
- Prevent double consumption of the doorbell item during placement.

## 2.0.0 — WHIP conversion
- Native inventory, interactions, WHIP phone integration, real voice lines and in-game settings.
- Removed the legacy standalone phone UI and development assets.

## Repository packaging
- Expanded documentation, release notes, issue templates and static validation workflow.
- Excluded runtime device data from Git; no gameplay logic changed from 2.0.7.
