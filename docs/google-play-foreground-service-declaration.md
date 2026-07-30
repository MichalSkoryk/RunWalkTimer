# Google Play foreground-service declaration

Use this document when completing **Play Console > App content > Foreground
service permissions** for Base Pacer.

## App and manifest details

- Package name: `com.skoryk.base.pacer`
- Foreground service: `.WorkoutTimerService`
- Foreground service type: `specialUse`
- Permissions:
  - `android.permission.FOREGROUND_SERVICE`
  - `android.permission.FOREGROUND_SERVICE_SPECIAL_USE`
- Runtime prerequisites for this service type: none
- User trigger: the service starts only after the user taps **Start** for a
  configured workout.
- User visibility and control: an ongoing notification displays the current
  walk/run phase and remaining time, and provides **Pause/Resume**, **Skip
  phase**, and **Stop** actions.
- Termination: **Stop** ends the service immediately. It also ends
  automatically when the configured workout duration or interval count is
  complete, at which point its ongoing notification is removed.

The manifest already declares `android:foregroundServiceType="specialUse"`,
the two permissions above, and the required
`android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE` service property.

## Ready-to-paste Play Console answers

### Foreground service type / use case

Select **Special use**. If the form asks for a custom use-case name, enter:

> User-initiated background walk/run interval timer

### Description of the functionality

> Base Pacer runs a user-initiated walk/run interval countdown during an active workout. The countdown, optional metronome, transition cues, and completion timing must continue accurately when the app is in the background or the screen is locked. An ongoing notification clearly shows the current phase and remaining time and provides Pause, Resume, Skip phase, and Stop controls. The service starts only when the user taps Start and stops immediately when the user taps Stop or when the configured workout completes.

### User impact if the task is deferred

> If start-up is deferred, the workout will not begin when the user taps Start. The countdown, phase cues, optional metronome, and ongoing workout notification would begin late, so the exercise intervals would no longer match the user's requested timing.

### User impact if the task is interrupted

> If the task is interrupted, the active walk/run countdown and optional metronome can become inaccurate while the app is backgrounded or the screen is locked. Phase-transition and completion cues may be missed, and the notification's remaining time and Pause, Resume, Skip, and Stop controls may become unavailable. This would break the user-initiated workout until the app is reopened.

### Access instructions for review

> No account, sign-in, subscription, location permission, health-data permission, or special access is required. Open Base Pacer, enter non-zero Walk and Run durations, choose a workout limit, and tap Start. Press the device Home button or lock the screen to see the ongoing workout notification and its Pause/Resume, Skip phase, and Stop controls.

## Demonstration-video checklist

Record the Android app itself. A concise 30–60 second unlisted YouTube video is
appropriate. Make the link publicly accessible to anyone who has it and do not
require the reviewer to request access.

Show, in this order:

1. Launch **Base Pacer** and show that no sign-in is required.
2. Configure short Walk and Run times (for example, 10 seconds each).
3. Optionally enable one metronome so its background behavior is audible.
4. Tap **Start** so it is clear the foreground service is user initiated.
5. Show the in-app current phase and countdown.
6. Press Home, then open the notification shade.
7. Show the ongoing notification's phase, remaining time, and overall time.
8. Use **Pause**, then **Resume**, from the notification.
9. Use **Skip phase** and show that the phase changes.
10. Return to the app or notification and tap **Stop**; show that the ongoing
    notification disappears.
11. If practical, run a second very short workout to completion and show that
    the notification also disappears automatically.

The recording should visibly demonstrate both background operation and the
user's ability to stop it. Avoid editing out the transition from the app to the
notification shade.

## Consistency checklist before submission

- Keep the Store listing description consistent with the declaration: the app
  is a walk/run interval timer, not a location or health-data tracker.
- Do not select location, health, media playback, or data-sync foreground
  service types; this implementation does not use those capabilities.
- Upload an app bundle containing the manifest declarations above before
  completing the Play Console form.
- Use the same video URL in the declaration for this `specialUse` feature.
- If Play Console wording changes, preserve the substance of the answers:
  user-initiated, user-perceptible, cannot be deferred without breaking timing,
  explicitly stoppable, and automatically terminated on completion.

## Official references

- [Google Play foreground-service declaration requirements](https://support.google.com/googleplay/android-developer/answer/13392821)
- [Android `specialUse` foreground-service type](https://developer.android.com/develop/background-work/services/fgs/service-types#special-use)
