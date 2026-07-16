# Run/Walk Timer download site

This is a zero-build static site. It checks GitHub Releases in the visitor's
browser and links the download button to the newest uploaded, non-debug APK.

## Repository configuration

The site currently expects:

```text
https://github.com/MichalSkoryk/RunWalkTimer
```

If the repository uses another name, edit only `githubOwner` and `githubRepo`
in `config.js`.

Until the first release is published, the page deliberately shows **First
release not published yet** and does not offer a stale/local APK as the newest
version.

## Required GitHub release

1. Create a normal, non-draft GitHub Release, for example tag `v1.0.0`.
2. Attach a properly release-signed APK.
3. Prefer the stable filename `run-walk-timer.apk`.

The page also recognizes `app-release.apk` and
`app-arm64-v8a-release.apk`. It refuses assets containing `debug` unless
`allowDebugApk` is explicitly changed in `config.js`.

Do not publish the current `app-debug.apk` as a production download. It is
debug-signed, very large, and intended for development devices.

## Preview locally

From the Flutter project directory:

```powershell
python -m http.server 8080 --directory website
```

Then open `http://127.0.0.1:8080/`.

## GitHub Pages deployment

The repository workflow at `.github/workflows/pages.yml` uploads this folder
and deploys it to GitHub Pages whenever website files change on `main`. It can
also be started manually from the repository's **Actions** tab.

No GitHub token belongs in this site. Public releases can be read through the
unauthenticated GitHub API. The UI includes safe fallbacks for a missing
repository/release, a release without an APK, API rate limits, and offline use.
