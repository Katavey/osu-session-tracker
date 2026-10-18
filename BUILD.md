# Build on Windows

Requires Windows x64, Windows PowerShell 5.1, .NET Framework 4.x and its C# compiler
(`%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe`). No NuGet restore is needed.

1. Download the official [tosu v4.26.2 Windows release](https://github.com/tosuapp/tosu/releases/tag/v4.26.2).
2. Extract `tosu.exe` somewhere outside this repository.
3. From the repository root run Windows PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build.ps1 -Client stable -TosuExePath "D:\tools\tosu\tosu.exe"
```

Use `-Client lazer` to build the separate lazer edition with `OsuSessionTrackerLazer.exe`
in `dist/osu-session-tracker-v2.2.1-lazer/`. Keep both editions in separate folders.

The complete application is created in `dist/osu-session-tracker-v2.2.1-stable/`.
The build copies the explicitly supplied tosu executable; it does not download,
update or verify its origin. Use the official version linked above.
Personal settings, sessions and imported backgrounds are never copied by the build.

Optional smoke check:

```powershell
.\dist\osu-session-tracker-v2.2.1-stable\OsuSessionTracker.exe --self-test
```

Check `build-check.txt` in that folder. Do not ship test markers or runtime data.
To test source UI directly, run `app/Start.cmd` with tosu already running. `app/client.txt` selects `stable` (default) or `lazer`.

Keep UTF-8 BOM on PowerShell files containing Cyrillic; Windows PowerShell 5.1
needs it to decode those files correctly.

## Русский

Скачай и распакуй официальный tosu 4.26.2, затем выполни команду выше,
заменив путь на свой `tosu.exe`. Готовая папка появится в `dist/`.
Установки Node.js, Python или редактора кода для сборки не требуется.
