# Validation checklist

Run on a staging FiveM server with compatible WHIP dependencies and at least two players. Mark the checks only after observing the result. GitHub syntax checks are not a substitute for these in-game checks.

- [ ] Resource starts without missing exports, callbacks or asset errors.
- [ ] Inventory item is registered and displays correctly.
- [ ] Cancel placement: item retained. Confirm valid placement: exactly one item consumed.
- [ ] All three finishes stream; interactions appear at the door and ring illuminates the model.
- [ ] Owner receives phone ring/motion notifications; unrelated character cannot access private device data.
- [ ] Dashboard, History, Devices, settings, back navigation and camera controls fit the physical DUI phone screen.
- [ ] Manual snapshot shows the actual outward camera view, restores the phone camera and persists on reconnect/restart.
- [ ] Auto snapshot refreshes stale images when eligible; defers when moving, driving, talking or using Live View.
- [ ] Two players can speak both ways; walking away, hanging up or closing the app ends the line.
- [ ] Sharing grants access; revoking access prevents future requests and ends affected sessions.
- [ ] Live View pans, exits cleanly, and handles another routing bucket appropriately.
- [ ] Siren, GPS waypoint, motion setting and history filters function.
- [ ] Owner removes device and receives the item; non-owner removal fails.
- [ ] Saved devices survive a server restart. No private data is committed to Git.
- [ ] Check F8 and server logs for reliable event overflow and monitor idle/active resource performance with `resmon`.

Record the server artifact version, WHIP dependency versions, GTA build, test date and results in your own private test notes.
