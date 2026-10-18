# v2.2.1 — Multiplayer tracking & TikTok overlay

## English

- Added personal multiplayer scores to session tracking in stable and lazer, including pp, accuracy, mods, combo and FC detection.
- Improved stable multiplayer completion detection: checks judged objects and the final gameplay snapshot when returning to the lobby, including cases where tosu does not provide a normal results screen.
- Filters duplicate results, failed/aborted plays and other players' scores. A local, size-limited `app/multiplayer-diagnostic.log` records state transitions for troubleshooting; it is not uploaded automatically.
- Added a **Copy TikTok URL** button in overlay settings. It copies `http://127.0.0.1.nip.io:24051` (the actual port may differ). The tracker must remain open on the streaming PC.
- Centered the widget horizontally and vertically in its browser canvas. OBS keeps its existing local URL.

**Download:** use the matching `stable-Windows.zip` or `lazer-Windows.zip` for a full installation; tosu 4.26.2 is included. Keep editions in separate folders.

**Update:** close the tracker, back up its folder and extract **all contents** of the matching `UPDATE.zip` over it with replacement. Settings, history and imported backgrounds are preserved. Refresh the OBS/TikTok browser source after updating. For TikTok, copy the new URL from Settings.

Multiplayer pp is calculated play pp; profile pp gain still comes from the profile itself. A multiplayer result without an online score ID links to the map instead. Multiplayer capture depends on the telemetry available from tosu. This hobby app was fully built with AI; ideas and testing are by the owner. Third-party components belong to their authors. More updates are likely.

## Русский

- Добавлен учёт собственных скоров из мультиплеера в stable и lazer: pp, точность, моды, комбо и FC.
- Доработано определение завершения карты в мульти stable: учитываются обработанные объекты и финальные данные при возврате в лобби, в том числе без обычного экрана результатов tosu.
- Добавлены проверки дублей, фейлов, прерванных карт и чужих скоров. Локальный лог `app/multiplayer-diagnostic.log` ограничен по размеру и нужен для диагностики; автоматически он никуда не отправляется.
- В настройки оверлея добавлена кнопка **«Скопировать TikTok URL»**. Ссылка имеет вид `http://127.0.0.1.nip.io:24051` (порт может отличаться). Трекер должен быть открыт на компьютере со стримом.
- Виджет выровнен по центру горизонтально и вертикально. Прежняя локальная ссылка OBS сохранена.

**Скачать:** соответствующий `stable-Windows.zip` или `lazer-Windows.zip` — полная сборка с tosu 4.26.2. Не смешивай версии в одной папке.

**Обновить:** закрой трекер, сделай резервную копию и распакуй **всё содержимое** соответствующего `UPDATE.zip` поверх папки программы с заменой файлов. Настройки, история и свои фоны сохраняются. После обновления обнови источник браузера OBS/TikTok. Для TikTok скопируй новую ссылку из настроек.

pp мульти — расчётные pp конкретного скора; прирост профиля по-прежнему берётся из самого профиля. Без онлайн-ID карточка открывает карту. Запись мульти зависит от данных tosu. Программа полностью создана с помощью ИИ, идеи и тестирование — автор. Это проект ради прикола для друзей; сторонние компоненты принадлежат их авторам. Дальнейшие обновления вероятны.
