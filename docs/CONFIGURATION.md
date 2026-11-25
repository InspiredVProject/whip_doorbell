# Configuration reference

Access these settings from `/whip` → Settings → Vista Doorbell. Values below are the shipped defaults and in-game bounds defined in `config.lua` and `settings.lua`.

| Key | Default | Range / type | Purpose |
| --- | --- | --- | --- |
| MaxPerPlayer | 5 | 1–30 | Maximum devices per character |
| RingCooldown | 6 | 3–60 s | Delay before the same visitor can ring again |
| RingLightTime | 7000 | 1000–20000 ms | Ring light duration |
| ChimeRange | 30 | 5–60 m | Audible chime range |
| ChimeVolume | 0.7 | 0–1 | Chime volume |
| MotionRange | 6 | 2–15 m | Motion detection range |
| MotionCooldown | 60 | 15–600 s | Motion alert cooldown |
| HistoryLimit | 60 | 10–200 entries | Maximum history entries per device |
| ShowVisitorNames | false | Boolean | Show character names in visitor history |
| AutoPreview | true | Boolean | Automatic preview updates while the app is open |
| AutoPreviewMinutes | 5 | 5–10 min | Snapshot refresh interval |
| CameraFov | 98 | 40–120 | Camera field of view |
| NightStart | 20 | 0–23 h | Live View night vision start |
| NightEnd | 6 | 0–23 h | Live View night vision end |
| MaxPan | 55 | 10–90 | Camera pan limit |
| TalkRange | 4 | 2–10 m | Visitor proximity required for intercom |
| RingAnswerSeconds | 45 | 10–120 s | Time available to answer a ring |
| TalkSeconds | 180 | 30–600 s | Maximum intercom session |
| SirenTime | 8000 | 1000–20000 ms | Siren duration |
| DrawDistance | 80 | 20–150 m | Prop streaming distance |

The item ID `vista_doorbell` and the three model finish definitions are set in `config.lua`. They are not part of the registered in-game settings page. Changing these identifiers on an existing installation may affect saved devices or inventory items.
