# v2.1 — stable + lazer, redesigned history & OBS

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
