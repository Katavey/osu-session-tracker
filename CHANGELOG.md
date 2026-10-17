# Changelog

## 2.2 — session recap cards, smarter history & more OBS customization

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


## 2.1 — stable + lazer, redesigned history & OBS

This app was fully built with AI: code, UI and build setup were created through vibe coding. The owner provided ideas, requirements and testing. Third-party components belong to their authors. This is a hobby project made for fun with friends, with no grand ambitions. More updates are likely.

## Русский

- Две отдельные версии: **osu!stable** и **osu!lazer**. Для lazer добавлены новые ссылки на скоры, локальные фоны и отображение скорости модов.
- Большой архив с фильтрами по дням/месяцам, переключением сессий стрелками и горизонтальной лентой скоров. Лучший скор — кликабельная карточка; CSV сохранён.
- Новые настройки: скруглённые разделы, переключатели, тёмные списки и поля с кнопками −/+.
- Предпросмотр оформления, шрифта, фона, маскота и карточек; прослушивание приветствия. Отдельный браузерный предпросмотр OBS с демо-скорами и повтором анимаций, который не меняет эфир до «Применить».
- OBS: **0–5 недавних скоров**, отдельные переключатели лучшего скора и статистики, свой шрифт, три размера карточек, ширина панели, непрозрачность фона 0–100%, анимации none/slide/fade/pop.
- Золотая метка **BEST** со звездой и голубая **RECENT** с иконкой истории в программе, OBS и предпросмотрах.
- Пять плиток статистики: прирост pp профиля, FC с медалью, пройденные карты, время и сумма расчётных pp. Прогноз **(if FC … pp)** выделен плашкой на карточках и в OBS.
- Исправлено падение при закрытии выпадающих списков.

**Установка:** выбери `stable-Windows.zip` или `lazer-Windows.zip`, распакуй целиком и запусти соответствующий EXE. Держи версии в разных папках. Полные архивы включают tosu 4.26.2.

**Обновление старой stable 2.0.1:** закрой трекер, сохрани резервную копию папки и распакуй всё содержимое `stable-UPDATE.zip` поверх неё с заменой. Настройки, история и свои фоны не входят в архив и сохраняются. Этот UPDATE нельзя ставить в папку lazer. Для lazer скачай полный архив; для существующей тестовой lazer 2.1 скопируй его содержимое поверх своей папки после резервного копирования.

В OBS обнови источник «Браузер» и используй размеры/основной URL из настроек. Удали старые CSS-переопределения, если они мешают новым настройкам. Расчётные pp loved/unranked карт не равны приросту pp профиля. Если открыты обе игры, tosu следует активному клиенту; одновременный независимый трекинг двух игр не заявляется. Последняя закрываемая версия трекера закрывает связанный tosu.

Программа полностью создана с помощью ИИ; идеи и тестирование — автор. Это проект ради прикола для друзей, без больших претензий. Скорее всего, будут дальнейшие обновления. tosu и сторонние иконки созданы их авторами, лицензии приложены.

## English

- Separate **osu!stable** and **osu!lazer** editions, with lazer score URLs, local backgrounds and mod-rate display.
- Larger history window with day/month filters, arrow navigation, horizontal score browsing, a clickable best card and CSV export.
- Redesigned settings with rounded groups, switches, dark selectors and number steppers.
- Live appearance previews, voice playback and a separate demo OBS browser preview with animation replay. Draft changes do not affect the live overlay until Apply.
- OBS supports **0–5 recent cards**, independent best/statistics toggles, its own font, three card sizes, panel width, 0–100% panel-background opacity and none/slide/fade/pop animations.
- Gold **BEST**/star and blue **RECENT**/history badges across the app, OBS and previews.
- Five statistics tiles, an FC medal and a highlighted **(if FC … pp)** forecast in score cards and OBS.
- Fixed a dropdown-close crash.

**Install:** extract either full `stable-Windows.zip` or `lazer-Windows.zip` and run its EXE. Keep the editions in separate folders. Full archives include tosu 4.26.2.

**Update stable 2.0.1:** close the tracker, back up its folder and extract all `stable-UPDATE.zip` contents over it, replacing files. Settings, history and imported wallpapers are excluded and preserved. Do not apply this UPDATE to lazer. Download the full lazer archive instead; existing lazer 2.1 test users can copy its complete contents over their backed-up installation.

Refresh the OBS Browser source after updating. Copy the main overlay URL and suggested dimensions from settings, not the temporary demo-preview URL. Remove old custom CSS overrides if they block new settings. Calculated pp on loved/unranked maps is separate from actual profile pp gain. With both games open, tosu follows the active client; simultaneous independent tracking of both games is not claimed. The last running tracker edition closes its associated tosu.

Both editions include the latest user-tested interface changes and dropdown fix. The executables are unsigned. `SHA256SUMS.txt` contains archive checksums. GitHub's automatic Source code downloads are not runnable Windows builds.


## 2.0 + 2.0.1

## Русский — всё новое в 2.0 и 2.0.1

- Выбор из 5–10 установленных шрифтов с предпросмотром при первом запуске.
- Три темы: розовая, океан и лаванда.
- Галерея из трёх фонов, своё изображение и настройка затемнения.
- Компактные карточки, переключатели маскота и голосового приветствия.
- Плавная отключаемая анимация новых скоров.
- История сессий внутри программы, итоги, карточки, ссылки на скоры и CSV.
- Текущая сессия продолжает записываться во время просмотра истории.
- Прозрачный локальный оверлей OBS: прирост pp профиля, FC, число скоров,
  лучшие pp и длительность сессии.
- Карточки OBS как в программе: фон карты, ранг, официальные иконки модов,
  pp, точность, комбо, FC и попадания.
- Выбор последних 1–5 скоров и отдельный показ лучшего скора сессии.
- Оверлей использует выбранные язык, шрифт и цвет, настройки сохраняются.

**Скачать:** `Windows.zip` — полная программа с tosu; `UPDATE.zip` — обновление.
Для обновления закрой трекер и распакуй содержимое UPDATE поверх старой папки
с заменой. Настройки и история сохраняются. В OBS: **780 × 1000**, обнови источник.
Эта версия предназначена для osu!stable; lazer пока не проверен.

## English — everything new in 2.0 and 2.0.1

- First-launch selection from 5–10 installed fonts with a preview.
- Three themes: Rose, Ocean and Lavender.
- Three gallery wallpapers, custom image support and adjustable dimming.
- Compact cards, mascot and voice-greeting toggles.
- Optional smooth animations for new scores.
- In-app session history, summaries, score cards, score links and CSV export.
- Live recording continues while browsing history.
- Transparent local OBS overlay: profile pp gain, FCs, plays, best pp and duration.
- OBS cards match the app: backgrounds, ranks, official mod icons, pp,
  accuracy, combo, FC and hit judgments.
- Choose the latest 1–5 scores and toggle the session-best card separately.
- The overlay follows the selected language, font and color; preferences are saved.

**Download:** `Windows.zip` is the complete app with tosu; `UPDATE.zip` is for updating.
Close the tracker and extract all UPDATE contents over the old installation,
replacing files. History and preferences are preserved.
OBS Browser source: **780 × 1000**; refresh the source after updating.
This release targets osu!stable; lazer has not been validated.
