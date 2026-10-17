# v2.2 — session recap cards, smarter history & more OBS customization

This app was fully built with AI: code, UI and build setup were created through vibe coding. The owner provided ideas, requirements and testing. Third-party components belong to their authors. This is a hobby project made for fun with friends, with no grand ambitions. More updates are likely.

## English

- **Session recap PNG cards (1000 × 720):** player name, date, profile pp gain, FCs, passed maps, session duration, total calculated play pp and a best-play card with its map background and mod icons. Open **Session card** in the main window or archive. Choose the app wallpaper, best map background, your own image or no image, adjust dimming and edit the displayed name. Preview matches export.
- **Clearer session archive:** a permanent session list on the left, statistics and best play on the right; choose **horizontal or vertical** All Scores browsing. CSV export remains available.
- **Archive rules:** sessions need **3 scores by default**, configurable from 1 to 100. Empty sessions are no longer written. Short nonempty sessions are hidden by the selected threshold, not deleted; lowering it reveals them again. Existing empty history files are hidden without deleting old files.
- **Best-play rules:** toggle whether loved/unranked maps may become session best. Enabled by default. Disabled means only known **Ranked / Approved** maps qualify. Applies to the app, archive, recap PNG and OBS. All scores remain in the score list and totals. Older scores without recorded map status are excluded in ranked-only mode.
- **OBS:** animation speed **25–300%** (100% normal), plus **Rise, Bounce, Flip and Wipe** animations alongside None/Slide/Fade/Pop. Mint, Sunset and Midnight themes, an independent OBS theme selector, and all installed Windows fonts. No font downloads are required.
- **Complete lazer mod artwork:** 69 unique mods plus No Mod, with official badge icons across the app, archive, PNG and OBS. Original SVGs, mapping manifest and license notices are included.
- Fixed crowded compact-card pp/FC labels and overlapping settings navigation. All changes through the R6 test patch are included in this release.

**Download:** choose `osu-session-tracker-v2.2-stable-Windows.zip` or `osu-session-tracker-v2.2-lazer-Windows.zip`. Extract the entire folder and run its matching EXE. Keep stable and lazer in separate folders. Full archives include tosu 4.26.2. Automatic GitHub Source code archives are not runnable Windows builds.

**Update:** close the tracker, back up your folder and extract **all contents of the matching stable-UPDATE or lazer-UPDATE ZIP** over it, replacing files. Use the matching edition only. UPDATE assumes bundled tosu 4.26.2 is already present (2.1 and 2.2 installations); use a full archive for a clean install. Settings, session history and imported wallpapers are excluded from release files and preserved when merging folders. Refresh the OBS Browser source after updating.

Archive direction, minimum score count and loved/unranked best-play rules are under **Settings → Sessions → Apply**. Reopen the archive after changing its rules. OBS appearance and animation changes are under **Settings → OBS**; Apply updates the live overlay. Temporary browser preview URLs are for demo data only.

Calculated play pp on loved/unranked maps is separate from actual profile pp gain. With both games open, tosu follows the active client; simultaneous independent capture of both games is not claimed. EXEs are unsigned. `SHA256SUMS.txt` provides archive checksums.

## Русский

- **Карточки итогов PNG (1000 × 720):** ник, дата, прирост pp профиля, FC, пройденные карты, время, сумма расчётных pp и лучший скор с BG карты и модами. Кнопка **«Карточка итогов»** есть в главном окне и архиве. Можно выбрать фон программы, BG лучшей карты, своё изображение или отсутствие картинки, изменить затемнение и ник. Предпросмотр совпадает с экспортом.
- **Понятнее архив:** список сессий слева, статистика и лучший скор справа. Для «Все скоры» можно выбрать **горизонтальное или вертикальное** направление. Экспорт CSV сохранён.
- **Правила архива:** по умолчанию отображаются сессии **от 3 скоров**, порог настраивается от 1 до 100. Пустые сессии больше не записываются. Короткие непустые скрываются, но не удаляются — снижение порога вернёт их в архив. Старые пустые файлы скрываются без удаления.
- **Правила лучшего скора:** можно разрешить или запретить Loved / Unranked становиться лучшим скором. По умолчанию разрешено; при отключении участвуют только карты с известным статусом **Ranked / Approved**. Действует в программе, архиве, PNG и OBS. Общий список и счётчики сохраняют все скоры. В старых сессиях неизвестный статус исключается при этом фильтре.
- **OBS:** скорость анимаций **25–300%**, где 100% — обычная. Новые анимации: подъём, пружина, поворот и раскрытие. Темы «Мята», «Закат», «Полночь», отдельная тема OBS и все установленные шрифты Windows без скачивания.
- **Полный набор иконок lazer:** 69 модов + No Mod в программе, архиве, PNG и OBS. Оригинальные SVG, соответствия модов и лицензии приложены.
- Исправлены отступы pp/прогноза FC в компактных карточках и наложение заголовка на кнопки настроек. В релиз включены все изменения до тестового патча R6.

**Скачать:** выбери `osu-session-tracker-v2.2-stable-Windows.zip` или `osu-session-tracker-v2.2-lazer-Windows.zip`, распакуй папку целиком и запусти EXE своей игры. Не смешивай stable и lazer. Полные архивы содержат tosu 4.26.2. Автоматический Source code — исходники, не готовая программа.

**Обновление:** закрой трекер, сделай резервную копию папки и распакуй **всё содержимое соответствующего stable-UPDATE или lazer-UPDATE ZIP** поверх неё с заменой. UPDATE рассчитан на уже установленный tosu 4.26.2 (версии 2.1 и 2.2); для чистой установки используй полный архив. Настройки, история и свои фоны исключены из релиза и сохраняются при объединении папок. После обновления обнови источник «Браузер» OBS.

Направление архива, минимум скоров и Loved / Unranked для лучшего скора: **Настройки → Сессии → Применить**. Открой архив заново после изменения правил. Оформление и анимации OBS — во вкладке **OBS**; эфир меняется после «Применить». Временный браузерный предпросмотр использует демо-данные.

Расчётные pp Loved / Unranked не означают прирост pp профиля. Если открыты обе игры, tosu следует активному клиенту; независимый одновременный захват обеих игр не заявляется. EXE не подписаны; контрольные суммы — в `SHA256SUMS.txt`.

Программа полностью создана с помощью ИИ; идеи и тестирование — автор. Проект ради прикола для друзей, без больших претензий. Скорее всего, будут обновления. tosu и сторонние иконки принадлежат их авторам; лицензии сохранены.
