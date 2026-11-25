# Distribution and GitHub publishing

This archive is prepared for sharing; it does not include an MIT, GPL or other licence grant. Packaging an existing resource does not establish the right to redistribute it or its models, textures and other assets. The repository owner should verify the original permissions and select a licence only for material they have the authority to license.

For sharing with friends, create a private GitHub repository first, provided your original asset permissions allow this. Invite your friends as collaborators. Make it public only when the distribution rights and intended licence are confirmed.

Suggested repository name: `whip_doorbell`

Suggested description: `Vista Home — a WHIP-native smart video doorbell, camera snapshot app and two-way intercom for FiveM.`

Suggested topics: `fivem`, `whip`, `gta5`, `lua`, `roleplay`, `doorbell`.

## Upload

1. Extract the ZIP. Open the `whip_doorbell` folder containing `fxmanifest.lua` and `README.md`.
2. Create an empty GitHub repository (without an extra README or licence).
3. With Git installed, open a terminal in the extracted resource folder:

   ```sh
   git init
   git add .
   git commit -m "Release Vista Home 2.0.7"
   git branch -M main
   git remote add origin https://github.com/YOUR-USERNAME/whip_doorbell.git
   git push -u origin main
   ```

   Replace `YOUR-USERNAME` with your real account or organisation. Verify that `data/doorbells.json` is not included in the commit.
4. In GitHub, create a release tagged `v2.0.7` on `main`, title it `Vista Home 2.0.7 — WHIP Doorbell`, and copy the body from `docs/RELEASE_NOTES.md`. Attach the downloadable ZIP if desired.

No repository has been created or uploaded by this package.
