# Run/Walk Timer

A focused Flutter interval timer for Android 10 and newer.

[Download the newest APK][latest-release] · [Open the download website][website]

The launcher artwork uses the MIT-licensed Tabler Run icon. Attribution and
the complete license text are in [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

The workout always starts with **Walk**, then alternates with **Run**. You can
stop it in either of two ways:

- **Intervals:** one cycle is one Walk phase followed by one Run phase. The
  workout finishes after the requested number of full cycles.
- **Time:** phases repeat until the exact active workout time is reached. The
  workout can therefore finish partway through a phase. Time spent paused does
  not count.

## Included

- Separate minute/second inputs for walking and running.
- Total-time input in hours/minutes/seconds.
- Cycle-count input validated as an integer of 1 or more.
- Start, Pause, Resume, Restart, and Stop/reset behavior.
- Simultaneous current-interval and overall-workout countdowns, with the active
  Walk/Run mode always visible.
- A compact active-workout view that hides setup while running, keeps controls
  near the timers, and restores setup when paused or stopped.
- An ongoing Android notification with the current Walk/Run phase, interval and
  overall countdowns, and Pause/Resume and Stop actions.
- A live Sound cues switch that mutes transition and completion tones while
  leaving vibration feedback enabled.
- Clear normalized audio and vibration patterns for Walk, Run, and completion;
  competing media briefly ducks so cues remain audible.
- Drift-resistant timing based on active elapsed time, rather than subtracting
  one second per callback.
- Screen-awake behavior while a workout is running.
- Inline input validation, phase and workout progress, and TalkBack-friendly
  labels.
- Unit and widget tests.

## Project structure

```text
lib/
  controllers/       Timer lifecycle and periodic synchronization
  core/              Pure timeline calculations and formatting
  models/            Workout plan and snapshot types
  screens/           Composed app screen
  services/          Android sound, haptic, and screen-awake bridge
  theme/             Material 3 theme
  widgets/           Small reusable UI components
test/
  core/              Timeline and formatting unit tests
  widget_test.dart   Conditional UI, validation, and start-state tests
scripts/
  run_on_phone.ps1   Checks the project and launches it on an Android device
```

## One-time Windows setup

1. Install the latest stable [Flutter SDK for Windows][flutter-install] in a
   normal user-writable folder without spaces, such as
   `C:\Users\<you>\development\flutter`.
2. Add its `bin` folder to your user `PATH`, then open a new PowerShell
   window.
3. Install Android Studio and, in **SDK Manager**, install the Android SDK,
   Build-Tools, Command-line Tools, Platform-Tools, Emulator, CMake, and NDK.
4. Run:

   ```powershell
   flutter doctor --android-licenses
   flutter doctor
   ```

The project uses Flutter-managed compile/target SDK versions and sets only
`minSdk = 29`, which is Android 10.

### Current computer checklist

The project itself was generated, tested, and built here with Flutter 3.44.6
from a temporary SDK. Before relying on the phone launcher:

- Install Flutter in a permanent folder and add `flutter\bin` to your user
  `PATH`.
- In Android Studio, open **SDK Manager > SDK Tools**, select **Android SDK
  Command-line Tools (latest)**, and apply the change.
- Run `flutter doctor --android-licenses`, followed by `flutter doctor`.

The Android SDK, API 36, Build-Tools, emulator, NDK, and CMake are already
present on this computer. Flutter Doctor warnings about Chrome or Visual Studio
can be ignored for an Android-only project.

## Connect an Android 10+ phone

1. On the phone, open **Settings > About phone** and tap **Build number** seven
   times.
2. In **Developer options**, enable **USB debugging**.
3. Connect the phone using a data-capable USB cable.
4. Accept the RSA authorization prompt on the phone.
5. On Windows, install the manufacturer's [OEM USB driver][oem-driver] if the
   phone is not detected.
6. Check the connection:

   ```powershell
   flutter devices
   ```

The device should be listed as Android, not `unauthorized`. Android 10 should
use USB for this workflow; Android's modern wireless-debugging pairing is for
Android 11 and newer.

## Run on the phone

From this project folder:

```powershell
.\scripts\run_on_phone.ps1
```

The script runs dependency resolution, analysis, all tests, finds a connected
Android device, and starts `flutter run`. If more than one Android target is
connected:

```powershell
flutter devices
.\scripts\run_on_phone.ps1 -DeviceId "<device-id>"
```

For faster later launches after the checks have already passed:

```powershell
.\scripts\run_on_phone.ps1 -DeviceId "<device-id>" -SkipChecks
```

While `flutter run` is active, press `r` in the terminal for hot reload and
`q` to stop the debug session.

In Android Studio, you can instead open this project, select the connected phone
in the device menu, and run `lib/main.dart`. A VS Code launch configuration is
also included; select your Android device and run **Run/Walk Timer (connected
Android)**.

## Recommended test strategy

Use all three layers:

1. Run `flutter test` for the included fast timeline and UI regression tests.
2. Create an API 29 emulator to check the oldest supported Android version and
   an API 36 emulator to check current Android behavior.
3. Use a real phone for sound volume, vibration, pause/resume, phone-call
   interruptions, screen rotation, and a full-length outdoor session.

For quick manual cue testing, temporarily use 5-second Walk and Run durations
and 2 cycles. Verify that the initial Walk starts silently, entering Run plays
the high double cue, entering the next Walk plays the lower cue, and completion
uses the three-part cue.

## Build a signed release APK

Public APKs use a private release key; release builds never fall back to the
Flutter debug key. Copy `android/key.properties.example` to
`android/key.properties`, fill in the private keystore values, and run:

```powershell
flutter clean
flutter build apk --release
```

The resulting APK is written to
`build/app/outputs/flutter-apk/app-release.apk`. Keep both the keystore and
`android/key.properties` private and backed up securely. Future updates must be
signed with the same key.

The download website is deployed from `website/` by the GitHub Pages workflow
in `.github/workflows/pages.yml`. It discovers the newest published GitHub
Release dynamically and links directly to its non-debug APK asset.

## Background workouts

Starting a workout also starts an Android foreground service. Its ongoing
notification shows the current Walk/Run phase, current-interval countdown,
overall countdown, and Pause/Resume and Stop actions. The service uses Android's
monotonic clock and a partial wake lock while running, so paused time is excluded
and phase cues remain reliable with the screen off.

Android 13 and newer asks for notification permission when the first workout
starts. Allow it to see the notification and its controls in the notification
drawer. If permission is denied, Android may show the active workout only in its
system Task Manager rather than the notification drawer. The app shows a notice
with a shortcut to its Android notification settings when background controls
are unavailable.

When the selected duration or interval count is reached, the workout enters
its completed state, releases its wake lock, stops the foreground service, and
removes the ongoing notification. The completed result remains visible when
the app is open so the workout can be reviewed or restarted.

If Android's **Active apps > Stop** control, a reboot, or an app update interrupts
the foreground service, the next app launch restores the workout safely as
paused and recreates the notification. Resume continues from the most recent
saved checkpoint instead of displaying a timer with no service behind it.

[flutter-install]: https://docs.flutter.dev/install/manual
[oem-driver]: https://developer.android.com/studio/run/oem-usb
[latest-release]: https://github.com/MichalSkoryk/RunWalkTimer/releases/latest
[website]: https://michalskoryk.github.io/RunWalkTimer/
