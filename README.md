# Window Holder

[한국어](README.ko.md)

A menu bar app that fixes a common multi-monitor annoyance on macOS: when
your Mac goes to sleep and wakes back up, a brief hiccup in the display
signal can cause windows to jump to the wrong monitor or end up in the
wrong position. Window Holder remembers where every window was and puts it
back.

## How it works

1. **Display arrangement fingerprint**: combines each connected monitor's
   serial/resolution/screen coordinates into a fingerprint that identifies
   "this exact set of monitors, in this exact arrangement."
2. **Save**: every minute, and right before sleep (`willSleep`), it uses the
   Accessibility API to capture every app window's position/size and stores
   it keyed by the current fingerprint
   (`~/Library/Application Support/WindowHolder/layouts.json`).
3. **Restore**: on wake (`didWake` / `screensDidWake`), it recomputes the
   fingerprint and, if it matches a saved layout, moves every window back to
   its saved position/size. Since external monitors can take a few seconds
   to renegotiate, it waits for the display configuration to settle
   (debounced, with a hard cutoff) before restoring, plus one safety
   re-apply shortly after in case macOS reshuffles things again.

## Build & run

```bash
./build.sh
open WindowHolder.app
```

A menu bar icon appears (it won't show in the Dock — `LSUIElement`).

### Required on first launch: Accessibility permission

Reading and moving other apps' windows requires macOS's **Accessibility**
permission. On first launch the system will prompt for it; if permission
hasn't been granted, clicking the menu bar icon shows a
"⚠️ Accessibility permission required…" item that jumps straight to the
right System Settings page.

System Settings > Privacy & Security > Accessibility > check WindowHolder

## Menu items

- **Save Layout Now / Restore Layout Now**: manual triggers
- **Auto-save (every minute)**: turn off to only save right before sleep
- **Launch at Login**: registers/unregisters a login item via `SMAppService`
- **Language**: Korean/English UI, defaulting to whatever the system
  language is (matches `Locale.preferredLanguages`); pick Korean or English
  explicitly to override that. The choice is saved in `UserDefaults` and
  persists across relaunches.
- The bottom line shows the current display configuration and whether a
  layout is saved for it

## Known limitations

- Window matching first tries the **window title**, then falls back to
  **original ordering (index)**. Windows without a usable title (some
  utility apps), or multiple windows of the same app sharing an identical
  title (e.g. several blank Finder windows), may not match perfectly and
  could end up swapped.
- Full Screen windows or windows on a separate Space are only partially
  controllable via the Accessibility API — this is a macOS limitation, not
  something this app can fully work around.
- The app has to keep running to do anything (enabling "Launch at Login" is
  recommended).
- Even for the same physical monitor setup, macOS can occasionally fail to
  read a display's serial number on reconnect (more common on cheap/no-name
  monitors), which can make the fingerprint unstable. In practice the
  vendor/model portion alone is usually still stable, but this isn't
  guaranteed 100% of the time.
- Right before a saved layout is applied, minimized windows are briefly
  un-minimized (so their frame can actually be set) and then re-minimized —
  this is why you may see a window flash in and out of the Dock during
  restore. Most apps ignore frame changes on a minimized window, so this
  step is currently necessary for accurate restoration.

## Update notifications

On launch (and every 24 hours after that) the app checks
[GitHub Releases](https://github.com/owlhyxxn/window-holder/releases) for a
newer tag than the running build. If one exists, a
"🆕 Update available" item appears in the menu bar. Clicking it just opens
the release page — nothing is downloaded or installed automatically, since
this project is distributed as source and everyone builds it themselves.

For the notification to work correctly, cutting a new release means
updating two things together:
1. Bump `CFBundleShortVersionString` in `Resources/Info.plist` (e.g. `1.1.0`)
2. Create a matching GitHub release tag (e.g. `v1.1.0` — the `v` prefix is
   optional, both forms parse fine)

## About code signing

`build.sh` uses ad-hoc signing (`codesign --sign -`). That's fine for
personal local use, but the signature changes on every rebuild, which means
macOS may ask you to re-grant Accessibility permission each time you
rebuild. If re-approving every time gets annoying, consider signing with a
personal developer certificate in Xcode instead — a stable identity keeps
the permission grant across rebuilds.

## License

MIT — see [LICENSE](LICENSE).
