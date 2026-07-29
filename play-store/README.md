# Google Play listing package

This directory is the hand-off checklist for the English (`en-US`) Google Play
listing for **Base Pacer: Run/Walk Timer**. Store-ready raster assets belong in
`assets/`; exact copy that can be pasted into Play Console is in `listing/en-US/`.

## Asset manifest

| Status | File | Play requirement | Content direction |
| --- | --- | --- | --- |
| Ready | `assets/app-icon-512.png` | Exactly 512 x 512 px, 32-bit PNG, at most 1 MB | White Tabler Run mark on a square, full-bleed Base Pacer blue (`#235B83`) background. Google Play can apply its own mask and shadow. |
| Ready | `assets/feature-graphic-1024x500.png` | Exactly 1024 x 500 px, JPEG or 24-bit PNG without alpha | Branded Base Pacer graphic with the running mark and **Walk. Run. Repeat.** No version number, price, ranking, Play badge, download claim, or tip link. |
| Ready | `assets/phone/01-workout-setup-1080x1920.png` | Portrait 1080 x 1920 px, 24-bit PNG without alpha | Real idle setup screen with valid Walk and Run durations and both metronomes enabled. Device status/navigation bars are omitted. |
| Ready | `assets/phone/02-active-workout-1080x1920.png` | Portrait 1080 x 1920 px, 24-bit PNG without alpha | Real active **Run** phase with current and overall countdowns, progress, Skip, live BPM, Pause, and Stop. |
| Ready | `assets/phone/03-sound-settings-1080x1920.png` | Portrait 1080 x 1920 px, 24-bit PNG without alpha | Real idle Sound settings screen with enabled selectors and preview actions for all four cue categories. |
| Optional | `assets/phone/04-background-controls-1080x1920.png` | Portrait 1080 x 1920 px, JPEG or 24-bit PNG without alpha | Capture on a clean emulator if a fourth listing image is desired. Do not use a personal phone shade containing unrelated notifications; the declaration video will demonstrate these controls separately. |

Google Play needs at least two phone screenshots. The three ready images above
are a complete upload set and use a consistent 9:16 canvas suitable for store
promotion. The optional notification image is intentionally not fabricated from
a personal notification shade. Review every screenshot at full size before
upload and remove email addresses, unrelated notification content, device
identifiers, or other personal information.

## Existing asset audit

- `assets/branding/run_walk_timer_icon.png` is a 1024 x 1024, 32-bit ARGB PNG
  (8,966 bytes). Its Tabler Run artwork and `#235B83` color can be reused, but
  the file itself is not the required size and has transparent, baked rounded
  corners. It should not be uploaded directly as the Play icon.
- `assets/branding/tabler-run.svg` is the clean MIT-licensed source geometry.
  Attribution is already recorded in `THIRD_PARTY_NOTICES.md`.
- `website/favicon.svg` is a 64-unit web favicon with a rounded background; it
  is not a Play asset.
- Android launcher mipmaps range from 48 x 48 to 192 x 192 and are too small for
  the store icon.
- The phone illustration on `website/index.html` is HTML/CSS, not a screenshot
  of the actual app. It should not be submitted as a phone screenshot.
- No feature graphic or real app screenshots were present when this manifest
  was created.

## Rebuilding the graphics

The source background generated for the feature graphic is stored at
`source/feature-background-generated.png`. Recreate the final icon and feature
graphic from the repository root with:

```powershell
python play-store/tools/generate_graphics.py
```

The script requires Pillow and validates the final dimensions, RGB color mode,
and Play icon file-size limit before it succeeds.

The ready phone screenshots were created from privacy-safe 1080 x 2400 captures
under `raw/`. Raw device captures are intentionally ignored by Git; only the
cropped, status-bar-free final assets are kept in the repository. Rebuild their
store frames after capturing the three documented source filenames with:

```powershell
python play-store/tools/generate_phone_screenshots.py
```

## Exact listing copy

The files in `listing/en-US/` are the source of truth:

- `title.txt`: 26 of 30 characters.
- `short-description.txt`: 74 of 80 characters.
- `full-description.txt`: under the 4,000-character limit.
- `release-notes-v1.3.0.txt`: first-release notes for version 1.3.0.

Recommended listing configuration:

- App or game: **App**
- Category: **Health & Fitness**
- Pricing: **Free**
- Ads: **No**
- Website: `https://michalskoryk.github.io/RunWalkTimer/`
- Privacy policy: `https://michalskoryk.github.io/RunWalkTimer/privacy.html`
- Support/donation wording: keep it out of listing promotional copy. Tips are
  optional, go to the developer, and unlock no app functionality.

The developer contact email must be supplied in Play Console from the
developer's monitored public support address; it is intentionally not invented
in this repository.

## Final pre-upload checks

- [ ] Open every PNG and verify its pixel dimensions, color mode, and lack of
      unintended transparency.
- [ ] Confirm the icon remains clear at small size and contains no embedded
      rounded-square mask.
- [ ] Confirm the feature graphic is legible when reduced and contains no
      time-sensitive version number.
- [ ] Confirm screenshots show the release build with the final package name,
      app name, and current UI.
- [ ] Confirm all screenshots are free of personal notifications and debug
      banners.
- [ ] Paste the exact copy files into the English (United States) listing and
      preview the phone layout in Play Console.
- [ ] Recheck the public privacy-policy URL in a private browser window before
      submitting the release.
