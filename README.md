# osu! Session Tracker

**This app was fully built with AI:** the code, UI and build setup were created through vibe coding. The project owner provided ideas and requirements and tested the app. Third-party components, including tosu and osu! icons, were created by their respective authors.

A Windows desktop session tracker for **osu!stable**, built with AI assistance.
Track plays, FCs and pp, browse session history, and show score cards in OBS.

**Version: 2.0.1** · [Русский README](README.ru.md) · [Changelog](CHANGELOG.md)

## Download and run

Open this repository's **Releases** and download
`osu-session-tracker-v2.0.1-Windows.zip`. Extract the entire folder and run
`OsuSessionTracker.exe`. Keep `app` and `tosu` beside the executable.
The GitHub-generated “Source code” archives contain source files, not a ready-to-run build.

Windows 10/11 x64 with Windows PowerShell 5.1 and .NET Framework 4.x is required.
The launcher starts bundled tosu and closes its associated tosu process when the tracker exits.
Choose your language and font on first launch. Start a session before playing;
osu! can already be open. **osu!lazer support has not been validated in this release.**

## Features

- Session FC count, play count, best play, calculated play pp and actual profile pp change.
- Calculated pp can include loved/unranked maps; it does not mean the same pp was added to your profile.
- Score cards with map backgrounds, rank, official mod icons, accuracy, combo and hit judgments.
- Click a score to open its score page when its ID is available, otherwise its beatmap page.
- Session history with CSV export; recording continues while browsing older sessions.
- Russian/English UI, installed font selection, three themes, three wallpapers and custom images.
- Background dimming, compact cards, optional score animations, anime mascot and Japanese voice greeting.
- Celebration for a play confirmed to be in the profile's top five.
- Local OBS overlay with the latest 1–5 score cards and an optional session-best card.

## OBS setup

1. Open **Appearance / OBS** and enable the overlay.
2. Choose the recent-score count and whether to show the session best; click **Apply**.
3. Click **Copy OBS URL**.
4. Add a **Browser** source in OBS, paste the URL and set its size to **780 × 1000**.
5. Keep the tracker running. After updating, refresh the OBS source.

The local URL is normally `http://127.0.0.1:24051/`; a free port up to 24059
is selected if needed. Always copy the actual URL from settings.
Unused space is transparent. Overlay HTTP behavior and browser rendering were tested;
capture inside OBS itself was not tested.

## Updating and personal data

Close the app and extract the complete `UPDATE.zip` over the old installation,
replacing files. Settings and history are not included in the update.

- `app/settings.json`: preferences
- `app/sessions/`: session history
- `app/user-backgrounds/`: imported wallpapers

These paths are ignored by Git. Share the original release ZIP, not your used installation.
The application receives local gameplay data from tosu. Profile features can make
requests to osu! services; this is not a completely offline application.
The executable is not digitally signed.

## Build from source

See [BUILD.md](BUILD.md). Source is in `app/` and `src/Launcher.cs`.
The repository does not include the tosu executable; the full Windows release does.

## Credits and licensing

- [tosu](https://github.com/tosuapp/tosu), bundled version 4.26.2: LGPL-3.0; see `third-party/tosu/`.
- osu-web mod artwork: AGPL-3.0; license, attribution and source SVGs are in `app/assets/`.
- Backgrounds and mascot were generated with AI. Japanese speech is synthetic; see the asset notices.

See [LICENSE-STATUS.md](LICENSE-STATUS.md) for the original tracker code.
This is a community project and is not affiliated with osu! or ppy.

## Bug reports

Open an Issue with the app version, Windows version, client (stable), steps to
reproduce and the expected/actual result. Remove personal information from logs
and screenshots before sharing them. Do not post your settings or complete session history.
