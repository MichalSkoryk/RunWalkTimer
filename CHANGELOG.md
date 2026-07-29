# Changelog

## 1.3.0 - Unreleased

- Renamed the app to Base Pacer: Run/Walk Timer.
- Added in-app and notification controls to skip the remaining current phase.
- Added live 70–180 BPM controls for the active metronome phase.
- Live BPM changes persist per phase and take effect cleanly on the next beat.
- Changed the Android application ID to `com.skoryk.basepacer` for the first
  Google Play release.
- Added a public privacy policy and an in-app link that opens it in the browser.
- Added Play Store listing copy, graphics, screenshots, and foreground-service
  declaration guidance.

## 1.2.0 - 2026-07-19

- Reworked Workout setup into compact phase and goal rows to reduce scrolling.
- Reworked Sound settings into compact selectors with inline preview actions.
- Kept Support immediately left of Settings and Settings at the far right.
- Combined each duration into one formatted MM:SS or HH:MM:SS input.
- Added independent 70–180 BPM metronomes for walking and running.
- Added persistent Sound settings with selectable and previewable Walk, Run,
  completion, and metronome sounds.
- Added background-safe, drift-resistant metronome scheduling on Android.

## 1.0.3 - 2026-07-18

- Added an optional developer-support link to buycoffee.to.
- Added a matching support section to the download website.

## 1.0.2 - 2026-07-16

- Replaced short device-dependent beeps with clearer normalized audio cues.
- Briefly lowers competing media audio while a workout cue is playing.
- Stops the foreground workout service when the target duration is reached.
- Removes the ongoing notification immediately when a workout completes.

## 1.0.1 - 2026-07-16

- Replaced the stock Flutter launcher artwork with the Tabler Run icon.
- Added adaptive, round, monochrome, and legacy Android launcher variants.
- Updated the download website favicon and brand mark to match the app.

## 1.0.0 - 2026-07-16

- Added configurable Walk and Run countdown intervals.
- Added Time and Intervals workout goals.
- Added overall-workout and current-phase countdowns.
- Added pause, resume, stop, and restart controls.
- Added optional sound cues and vibration feedback.
- Added Android background notification controls.
- Added a responsive GitHub-powered APK download website.
