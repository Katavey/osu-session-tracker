# osu! Session Tracker

**This app was fully built with AI:** the code, UI and build setup were created through vibe coding. The project owner provided ideas and requirements and tested the app. Third-party components, including tosu and osu! icons, were created by their respective authors.

A hobby project made for fun with friends, with no grand ambitions. More updates are likely.

A Windows desktop session tracker for **osu!stable and osu!lazer** (separate editions), built with AI assistance.
Track plays, FCs and pp, browse session history, and show score cards in OBS.

**Version: 2.1** · [Русский README](README.ru.md) · [Changelog](CHANGELOG.md)

## Download and run

Open this repository's **Releases** and download
`osu-session-tracker-v2.1-stable-Windows.zip` or
`osu-session-tracker-v2.1-lazer-Windows.zip`. Extract the entire folder and run
`OsuSessionTracker.exe` (stable) or `OsuSessionTrackerLazer.exe` (lazer). Keep editions in separate folders. Keep `app` and `tosu` beside the executable.
The GitHub-generated “Source code” archives contain source files, not a ready-to-run build.

Windows 10/11 x64 with Windows PowerShell 5.1 and .NET Framework 4.x is required.
The launcher starts bundled tosu and closes its associated tosu process when the tracker exits.
Choose your language and font on first launch. Start a session before playing;
osu! can already be open. With both games open, tosu follows the active client. Simultaneous independent tracking of both games is not claimed.

## Features

- Session FC count, play count, best play, calculated play pp and actual profile pp change.
- Calculated pp can include loved/unranked maps; it does not mean the same pp was added to your profile.
- Score cards with map backgrounds, rank, official mod icons, accuracy, combo and hit judgments.
- Click a score to open its score page when its ID is available, otherwise its beatmap page.
- Larger session history with day/month filters, horizontal score browsing, a clickable best card and CSV export; recording continues while browsing older sessions.
- Russian/English UI, installed font selection, three themes, three wallpapers and custom images.
- Background dimming, compact cards, optional score animations, anime mascot and Japanese voice greeting.
- Celebration for a play confirmed to be in the profile's top five.
- Local OBS overlay with 0–5 recent cards, optional best/statistics, its own font, card sizes, width, background opacity and animations.
- Live appearance previews and an isolated browser demo preview for OBS.
- BEST/RECENT badges, five statistics tiles with an FC medal, and highlighted (if FC … pp) forecasts.
- Rounded settings groups, switches, selectors and number steppers.

## OBS setup

1. Open **Appearance / OBS** and enable the overlay.
2. Choose the recent-score count and whether to show the session best; click **Apply**.
3. Click **Copy OBS URL**.
4. Add a **Browser** source in OBS, paste the URL and use the suggested dimensions shown in the OBS settings tab.
5. Keep the tracker running. After updating, refresh the OBS source.

The local URL is normally `http://127.0.0.1:24051/`; a free port up to 24059
is selected if needed. Always copy the actual URL from settings.
Unused space is transparent. Use the main URL, not the temporary demo-preview URL.
Old custom CSS overrides may prevent new appearance settings from taking effect.

## Updating and personal data

For stable 2.0.1, close the app, back up its folder and extract the complete
`osu-session-tracker-v2.1-stable-UPDATE.zip` over it, replacing files. Do not apply
this update to lazer. Full archives can also be copied over the matching edition.
Settings and history are not included in release archives.

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
- Font Awesome Free score icons: CC BY 4.0; see `app/assets/FONT-AWESOME-LICENSE.txt` and `score-icons/ATTRIBUTION.txt`.
- Backgrounds and mascot were generated with AI. Japanese speech is synthetic; see the asset notices.

See [LICENSE-STATUS.md](LICENSE-STATUS.md) for the original tracker code.
This is a community project and is not affiliated with osu! or ppy.

## Bug reports

Open an Issue with the app version, Windows version, client (stable/lazer), steps to
reproduce and the expected/actual result. Remove personal information from logs
and screenshots before sharing them. Do not post your settings or complete session history.
