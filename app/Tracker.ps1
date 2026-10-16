$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type -Path (Join-Path $PSScriptRoot 'Theme.cs') -ReferencedAssemblies System.Windows.Forms,System.Drawing
Add-Type -Path (Join-Path $PSScriptRoot 'Feed.cs') -ReferencedAssemblies System,System.Core
Add-Type -Path (Join-Path $PSScriptRoot 'Overlay.cs') -ReferencedAssemblies System,System.Core
$script:feed=New-Object TosuFeed
$script:feedGeneration=-1
[ScoreCards]::IconDirectory=Join-Path $PSScriptRoot 'assets/mods'
. (Join-Path $PSScriptRoot 'Localization.ps1')
. (Join-Path $PSScriptRoot 'Features.ps1')
. (Join-Path $PSScriptRoot 'Desktop.ps1')
$dataDir = Join-Path $PSScriptRoot 'sessions'
[IO.Directory]::CreateDirectory($dataDir) | Out-Null
$script:session = $null
$script:socket = $null
$script:connectTask = $null
$script:receiveTask = $null
$script:buffer = New-Object byte[] 262144
$script:message = New-Object IO.MemoryStream
$script:armed = $false
$script:resultSince = $null
$script:profile = $null
$script:retry = [datetime]::MinValue
function Save-Session {
    if ($script:session) {
        $path = Join-Path $dataDir ($script:session.id + '.json')
        $temp = $path + '.tmp'
        $script:session | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $temp -Encoding UTF8
        Move-Item -LiteralPath $temp -Destination $path -Force
    }
}
function New-Session {
    if ($script:session -and !$script:session.ended) { $script:session.ended=(Get-Date).ToString('o') }
    Save-Session
    $script:session = [pscustomobject]@{id=[guid]::NewGuid().ToString(); started=(Get-Date).ToString('o'); ended=$null; player=$null; mode=$null; baseline=$null; latest=$null; plays=@()}
    $script:armed=$false
    Save-Session
    Refresh-View
}
function End-Session {
    if(!$script:session -or $script:session.ended){return}
    $script:session.ended=(Get-Date).ToString('o')
    $script:armed=$false
    Save-Session
    Refresh-View
}
function Refresh-View {
    if (!$script:session) { return }
    $s=$script:session
    $plays=@($s.plays)
    $sum=($plays | Measure-Object pp -Sum).Sum
    $best=$plays | Sort-Object pp -Descending | Select-Object -First 1
    $fc=@($plays | Where-Object fc).Count
    $gain=T 'ожидание профиля' 'waiting for profile'
    if ($null -ne $s.baseline -and $null -ne $s.latest) { $gain=('{0:+0.00;-0.00;0.00} pp' -f ($s.latest-$s.baseline)) }
    $endTime=if($s.ended){[datetime]$s.ended}else{Get-Date}
    $duration=$endTime-[datetime]$s.started
    if($endButton){$endButton.Enabled=!$s.ended}
    if($sessionLabel){$sessionLabel.Text=if($s.ended){T 'СЕССИЯ ЗАВЕРШЕНА • итоги сохранены' 'SESSION FINISHED • results saved'}else{(T 'СЕССИЯ АКТИВНА • ' 'SESSION ACTIVE • ')+([datetime]$s.started).ToString('dd.MM · HH:mm')}}
    $summary.Text=T "ПРИРОСТ ПРОФИЛЯ: $gain`r`nFC: $fc     |     Завершено карт: $($plays.Count)     |     Время: $([int]$duration.TotalMinutes) мин`r`nСумма pp карт: $([math]::Round([double]$sum,2)) pp" "PROFILE PP GAIN: $gain`r`nFC: $fc     |     Maps passed: $($plays.Count)     |     Time: $([int]$duration.TotalMinutes) min`r`nTotal play pp: $([math]::Round([double]$sum,2)) pp"
    if($emptyLabel){$emptyLabel.Visible=($plays.Count -eq 0)}
    $cardsKey="$($s.id)|$($plays.Count)"
    if($script:cardsKey -eq $cardsKey){return}
    $script:cardsKey=$cardsKey
    $bestCards.BeginUpdate()
    $bestEntries=New-Object 'System.Collections.Generic.List[ScoreEntry]'
    if($best){$bestEntries.Add((Make-ScoreEntry $best))}
    $bestCards.ReplaceCards($bestEntries.ToArray())
    $bestCards.EndUpdate()
    $bestEmpty.Visible=(!$best)
    $list.BeginUpdate()
    $scroll=$list.TopIndex
    $entries=New-Object 'System.Collections.Generic.List[ScoreEntry]'
    foreach($p in ($plays | Sort-Object time -Descending)) {
        $entries.Add((Make-ScoreEntry $p))
    }
    $list.ReplaceCards($entries.ToArray())
    if($list.Items.Count -gt 0){$list.TopIndex=[math]::Min($scroll,$list.Items.Count-1)}
    $list.EndUpdate()
}
function Make-ScoreEntry($p) {
    $item=New-Object ScoreEntry
    $item.Key="$($p.time)|$($p.beatmapId)|$($p.score)"
    $item.Map=$p.map;$item.Mods=$p.mods;$item.Rank=$p.rank;$item.Time=([datetime]$p.time).ToString('HH:mm:ss')
    $item.Pp=$p.pp;$item.Accuracy=$p.accuracy;$item.Combo=$p.combo;$item.Fc=$p.fc
    $item.Stars=$p.stars;$item.FcPp=$p.fcPp;$item.Background=$p.background;$item.Url=Get-ScoreUrl $p
    $item.Hits=if($p.hitText){$p.hitText}else{"MISS $($p.misses)"}
    return $item
}
function Get-ScoreUrl($p) {
    if($p.server -and $p.server -ne 'ppy.sh' -and $p.server -ne 'osu.ppy.sh'){return $null}
    if($p.scoreId -gt 0){
        if($p.client -eq 'lazer'){return "https://osu.ppy.sh/scores/$($p.scoreId)"}
        $ruleset=@('osu','taiko','fruits','mania')[[math]::Max(0,[math]::Min(3,[int]$p.mode))]
        return "https://osu.ppy.sh/scores/$ruleset/$($p.scoreId)"
    }
    if($p.beatmapId -gt 0){return "https://osu.ppy.sh/b/$($p.beatmapId)"}
    return $null
}
function Process-Packet($d) {
    $s=$script:session
    if(!$s -or $s.ended){return}
    $profile=$d.profile
    if ($profile.id -gt 0 -and $null -ne $profile.pp -and $profile.pp -ge 0) {
        $mode=[int]$profile.mode.number
        if ($null -ne $s.player -and ($s.player -ne $profile.id -or $s.mode -ne $mode)) {
            $s.ended=(Get-Date).ToString('o'); New-Session; $s=$script:session
        }
        if($null -eq $s.baseline) { $s.player=$profile.id; $s.mode=$mode; $s.baseline=[double]$profile.pp }
        if($s.latest -ne $profile.pp) { $s.latest=[double]$profile.pp; Save-Session }
    }
    $state=[int]$d.state.number
    if($state -eq 2) {
        $script:armed=$true; $script:resultSince=$null
        $script:map=$d.beatmap
        $script:play=$d.play
        $bgKey="$($d.beatmap.checksum)|$($d.beatmap.id)|$($d.directPath.beatmapFile)|$($d.files.background)"
        if($script:bgKey -ne $bgKey){$script:bgKey=$bgKey;$script:background=Resolve-Background $d}
    } elseif($state -eq 7 -and $script:armed) {
        $r=$d.resultsScreen
        if($r.score -le 0 -or $r.rank -eq 'F') {return}
        $script:armed=$false
        $m=$script:map
        if(!$script:background){$script:background=Resolve-Background $d}
        $fc=($m.stats.maxCombo -gt 0 -and $r.maxCombo -ge $m.stats.maxCombo -and $r.hits.'0' -eq 0)
        $p=[pscustomobject]@{time=(Get-Date).ToString('o'); map="$($m.artist) - $($m.title) [$($m.version)]"; beatmapId=$m.id; mods=$(if($r.mods.name){$r.mods.name}else{'NM'}); pp=[math]::Round([double]$r.pp.current,2); accuracy=[math]::Round([double]$r.accuracy,2); combo=$r.maxCombo; misses=$r.hits.'0'; fc=$fc; rank=$r.rank}
        $p | Add-Member -NotePropertyMembers @{stars=[double]$m.stats.stars.total;fcPp=[double]$r.pp.fc;background=$script:background;hitText="300: $($r.hits.'300')   100: $($r.hits.'100')   50: $($r.hits.'50')   MISS: $($r.hits.'0')";scoreId=[long]$r.scoreId;score=[long]$r.score;mode=[int]$r.mode.number;client=[string]$d.client;server=[string]$d.server}
        $s.plays=@($s.plays)+$p
        Queue-TopCheck $p $s.player
        Save-Session; Refresh-View
    } elseif($state -eq 7 -and $s.plays.Count -gt 0) {
        # Online score ID can arrive after the first results packet.
        $last=$s.plays[-1]; $r=$d.resultsScreen
        if($last.score -eq $r.score -and $last.combo -eq $r.maxCombo -and $last.beatmapId -eq $d.beatmap.id){
            $changed=$false
            if($last.scoreId -le 0 -and $r.scoreId -gt 0){$last.scoreId=[long]$r.scoreId;$changed=$true}
            if($null -ne $r.pp.current -and $last.pp -ne [math]::Round([double]$r.pp.current,2)){$last.pp=[math]::Round([double]$r.pp.current,2);$last.fcPp=[double]$r.pp.fc;$changed=$true}
            if($changed){$script:cardsKey=$null;Save-Session;Refresh-View}
        }
    } elseif($state -ne 7) { $script:armed=$false; $script:resultSince=$null }
}
function Disconnect {
    if($script:feed){$script:feed.Dispose()}
    if($script:socket){$script:socket.Dispose()}
    $script:socket=$null; $script:connectTask=$null; $script:receiveTask=$null
    $script:message.SetLength(0); $script:armed=$false
    $script:retry=(Get-Date).AddSeconds(3)
}
function Resolve-Background($d) {
    # tosu paths can be absolute or relative to osu!, Songs or the map folder.
    $roots=New-Object 'System.Collections.Generic.List[string]'
    if($d.folders.game){$roots.Add([string]$d.folders.game)}
    if($d.folders.songs){
        if([IO.Path]::IsPathRooted($d.folders.songs)){$roots.Add([string]$d.folders.songs)}
        elseif($d.folders.game){$roots.Add((Join-Path $d.folders.game $d.folders.songs))}
    }
    if($d.folders.game){$roots.Add((Join-Path $d.folders.game 'Songs'))}
    $songRoots=@($roots.ToArray())
    foreach($root in $songRoots){
        foreach($folder in @($d.folders.beatmap,$d.directPath.beatmapFolder)){
            if($folder){if([IO.Path]::IsPathRooted($folder)){$roots.Add([string]$folder)}else{$roots.Add((Join-Path $root $folder))}}
        }
    }
    foreach($candidate in @($d.directPath.beatmapBackground,$d.files.background)){
        if(!$candidate){continue}
        if([IO.Path]::IsPathRooted($candidate) -and [IO.File]::Exists($candidate)){return [string]$candidate}
        foreach($root in $roots){$full=Join-Path $root $candidate;if([IO.File]::Exists($full)){return $full}}
    }
    # Fallback: read the background event directly from the local .osu file.
    foreach($candidate in @($d.directPath.beatmapFile,$d.files.beatmap)){
        if(!$candidate){continue}
        $maps=if([IO.Path]::IsPathRooted($candidate)){@($candidate)}else{@($roots | ForEach-Object {Join-Path $_ $candidate})}
        foreach($mapFile in $maps){
            if(![IO.File]::Exists($mapFile)){continue}
            foreach($line in [IO.File]::ReadLines($mapFile)){
                if($line -match '^\s*(?:0|Background)\s*,\s*\d+\s*,\s*"([^"]+)"'){
                    $bg=Join-Path ([IO.Path]::GetDirectoryName($mapFile)) $Matches[1]
                    if([IO.File]::Exists($bg)){return $bg}
                }
            }
        }
    }
    return $null
}
$form=New-Object SessionForm
if(!$script:languageChosen -and $env:OSU_TRACKER_UI_TEST -ne '1' -and !(Select-Language)){$script:topHttp.Dispose();$form.Dispose();return}
if(!$script:fontChosen -and $env:OSU_TRACKER_UI_TEST -ne '1' -and !(Select-FirstFont)){$script:topHttp.Dispose();$form.Dispose();return}
[SessionTheme]::RoundWindow($form)
$form.Text='osu! session tracker 2.0.1'; $form.Size=New-Object Drawing.Size(1140,920)
$form.MinimumSize=New-Object Drawing.Size(1020,860)
$form.StartPosition='CenterScreen'
$form.BackColor=[Drawing.Color]::FromArgb(23,20,29); $form.ForeColor=[Drawing.Color]::FromArgb(242,234,246)
$wallpaperPath=Join-Path $PSScriptRoot 'assets/menu-background.png'
if([IO.File]::Exists($wallpaperPath)){
    $wallpaperSource=[Drawing.Image]::FromFile($wallpaperPath)
    $form.Wallpaper=New-Object Drawing.Bitmap($wallpaperSource);$wallpaperSource.Dispose()
}
$script:uiFont=$script:fontName
$form.Font=New-Object Drawing.Font($script:uiFont,10)
function Label($text,$x,$y,$w,$h,$size=11) {
    $l=New-Object SessionLabel; $l.Text=$text; $l.Location=New-Object Drawing.Point($x,$y); $l.Size=New-Object Drawing.Size($w,$h); $l.Font=New-Object Drawing.Font($script:uiFont,$size); $form.Controls.Add($l); return $l
}
$title=Label 'osu!  /  session tracker 2.0.1' 30 20 700 45 25
$title.ForeColor=[Drawing.Color]::FromArgb(255,155,200)
$sessionLabel=Label '' 33 76 700 24 10
$sessionLabel.ForeColor=[Drawing.Color]::FromArgb(180,163,193)
$status=Label 'Подключение к tosu…' 33 109 1000 26 10
$summary=Label '' 33 157 1040 145 13
$summary.BackColor=[Drawing.Color]::FromArgb(38,31,46)
$summary.Padding=New-Object Windows.Forms.Padding(20,12,12,8)
$summary.Anchor='Top,Left,Right'
[SessionTheme]::Round($summary,16)
$bestHeader=Label 'ЛУЧШИЙ ПЛЕЙ СЕССИИ' 33 320 650 26 10
$bestHeader.ForeColor=[Drawing.Color]::FromArgb(255,195,222)
$bestCards=New-Object ScoreCards
$bestCards.Location=New-Object Drawing.Point(33,354);$bestCards.Size=New-Object Drawing.Size(1055,110)
$bestCards.Anchor='Top,Left,Right';$form.Controls.Add($bestCards)
[SessionTheme]::Round($bestCards,14)
$bestEmpty=Label 'Твой лучший плей появится здесь ♡' 55 385 950 32 12
$bestEmpty.ForeColor=[Drawing.Color]::FromArgb(160,146,175)
$section=Label 'СКОРЫ СЕССИИ' 33 478 650 26 10
$section.ForeColor=[Drawing.Color]::FromArgb(174,155,189)
$list=New-Object ScoreCards
$list.Location=New-Object Drawing.Point(33,513); $list.Size=New-Object Drawing.Size(1055,255)
$list.Anchor='Top,Bottom,Left,Right'
$form.Controls.Add($list)
$openScoreHandler={param($sender,$eventArgs)
    $url=$sender.ClickedUrl
    if($url -match '^https://osu\.ppy\.sh/(scores/(?:osu/|taiko/|fruits/|mania/)?[1-9][0-9]*|b/[1-9][0-9]*)$'){
        try {Start-Process $url} catch {[Windows.Forms.MessageBox]::Show((T 'Не удалось открыть браузер. Ссылка: ' 'Could not open browser. Link: ')+$url,(T 'Открыть скор' 'Open score')) | Out-Null}
    }
}
$list.Add_ScoreClicked($openScoreHandler)
$bestCards.Add_ScoreClicked($openScoreHandler)
[SessionTheme]::Round($list,14)
$emptyLabel=Label 'Пока нет скоров. Пройди карту — результат появится здесь.' 55 537 930 32 11
$emptyLabel.ForeColor=[Drawing.Color]::FromArgb(160,146,175)
$emptyLabel.BringToFront()
function Button($text,$x,$width,$primary,$handler) {
    $b=New-Object SessionButton; $b.Text=$text; $b.Location=New-Object Drawing.Point($x,794); $b.Size=New-Object Drawing.Size($width,44); $b.Anchor='Bottom,Left'; $b.Primary=$primary
    $b.Font=New-Object Drawing.Font($script:uiFont,9,[Drawing.FontStyle]::Bold)
    $b.Add_Click($handler); $form.Controls.Add($b); return $b
}
$newButton=Button 'Новая сессия' 33 180 $true {
    if($script:session.ended -or [Windows.Forms.MessageBox]::Show((T 'Завершить текущую сессию и начать новую? История сохранится.' 'Finish the current session and start a new one? Your history will be saved.'),(T 'Новая сессия' 'New session'),'YesNo') -eq 'Yes'){New-Session}
}
$endButton=Button 'Завершить сессию' 225 205 $false {End-Session}
$historyButton=Button 'История сессий' 442 185 $false {Show-SessionHistory}
$exportButton=Button 'Экспорт CSV' 639 170 $false {
    $dialog=New-Object Windows.Forms.SaveFileDialog; $dialog.Filter='CSV (*.csv)|*.csv'; $dialog.FileName='osu-session.csv'
    if($dialog.ShowDialog() -eq 'OK'){$script:session.plays | Export-Csv -LiteralPath $dialog.FileName -NoTypeInformation -Encoding UTF8}
    $dialog.Dispose()
}
$voiceText=if($script:voiceEnabled){'Голос: вкл'}else{'Голос: выкл'}
$voiceButton=Button $voiceText 822 190 $false {Toggle-Voice}
$hint=Label 'pp карт — расчёт tosu. Прирост профиля обновляется отдельно.' 33 850 1020 24 9
$hint.ForeColor=[Drawing.Color]::FromArgb(153,137,166); $hint.Anchor='Bottom,Left'
$noticePanel=New-Object Windows.Forms.Panel
$noticePanel.Size=New-Object Drawing.Size(770,500)
$noticePanel.BackColor=[Drawing.Color]::FromArgb(51,35,62)
[SessionTheme]::Round($noticePanel,24)
$form.Controls.Add($noticePanel);$noticePanel.Visible=$false
$mascot=New-Object Windows.Forms.PictureBox
$mascot.Location=New-Object Drawing.Point(5,10);$mascot.Size=New-Object Drawing.Size(295,480)
$mascot.SizeMode='Zoom'
$mascotPath=Join-Path $PSScriptRoot 'assets/mascot.png'
if([IO.File]::Exists($mascotPath)){
    $sourceImage=[Drawing.Image]::FromFile($mascotPath)
    $mascot.Image=New-Object Drawing.Bitmap($sourceImage);$sourceImage.Dispose()
}
$noticePanel.Controls.Add($mascot)
$noticeTitle=New-Object SessionLabel
$noticeTitle.Location=New-Object Drawing.Point(310,150);$noticeTitle.Size=New-Object Drawing.Size(430,75)
$noticeTitle.Font=New-Object Drawing.Font($script:uiFont,23,[Drawing.FontStyle]::Bold)
$noticeTitle.ForeColor=[Drawing.Color]::FromArgb(255,171,211)
$noticePanel.Controls.Add($noticeTitle)
$noticeText=New-Object SessionLabel
$noticeText.Location=New-Object Drawing.Point(312,240);$noticeText.Size=New-Object Drawing.Size(420,170)
$noticeText.Font=New-Object Drawing.Font($script:uiFont,13)
$noticePanel.Controls.Add($noticeText)
$noticeClose=New-Object SessionButton
$noticeClose.Text='×';$noticeClose.Size=New-Object Drawing.Size(40,36);$noticeClose.Location=New-Object Drawing.Point(718,12)
$noticeClose.Add_Click({$noticePanel.Visible=$false});$noticePanel.Controls.Add($noticeClose)
$form.Add_Shown({Show-MascotNotice 'Welcome to osu!' (T "おかえりなさいませ、ご主人様 ♡`r`nС возвращением, господин!`r`nЛови ритм и ставь новые рекорды!" "おかえりなさいませ、ご主人様 ♡`r`nWelcome back, master!`r`nCatch the rhythm and set new records!") 10;Play-WelcomeVoice})
$script:lastRefresh=Get-Date
$timer=New-Object Windows.Forms.Timer; $timer.Interval=50
$timer.Add_Tick({
    try {Tick-Features} catch {}
    try {Tick-Overlay} catch {$hint.Text=T 'Не удалось обновить OBS. Проверь настройки оверлея.' 'Could not update OBS. Check overlay settings.'}
    try {
        foreach($sample in $script:feed.Drain()){
            if($script:feedGeneration -ne $sample.Generation){$script:feedGeneration=$sample.Generation;$script:armed=$false}
            $packet=$sample.Json | ConvertFrom-Json
            if($packet.state -and $packet.beatmap){
                Process-Packet $packet
                $status.Text="● tosu • $($packet.state.name) [$($packet.state.number)] • $(T 'записано' 'recorded'): $($script:session.plays.Count)"
                $status.ForeColor=[Drawing.Color]::LightGreen
            } elseif($packet.error){$status.Text="tosu: $($packet.error)";$status.ForeColor=[Drawing.Color]::Orange}
        }
        if($script:feed.Status -ne 'Connected'){
            $status.Text=T 'Ожидание tosu на 127.0.0.1:24050' 'Waiting for tosu at 127.0.0.1:24050'
            $status.ForeColor=[Drawing.Color]::Orange
        }
        if(((Get-Date)-$script:lastRefresh).TotalSeconds -ge 10){Refresh-View;$script:lastRefresh=Get-Date}
    } catch {
        try {Add-Content -LiteralPath (Join-Path $PSScriptRoot 'tracker-errors.log') -Value "$(Get-Date -Format o) $($_.Exception.ToString())" -Encoding UTF8} catch {}
        $status.Text=T 'Ошибка обработки данных tosu. Подробности в tracker-errors.log.' 'tosu data processing error. See tracker-errors.log.'
        $status.ForeColor=[Drawing.Color]::Orange
    }
})
$form.Add_FormClosing({$timer.Stop(); if($script:session -and !$script:session.ended){End-Session}; Disconnect; [MascotAudio]::Stop(); $script:topHttp.Dispose(); if($script:overlayServer){$script:overlayServer.Dispose()}; if($mascot.Image){$mascot.Image.Dispose()}})
function Apply-Language {
    [ScoreCards]::English=($script:language -eq 'en')
    $title.Text='osu!  /  session tracker 2.0.1'
    $newButton.Text=T 'Новая сессия' 'New session'
    $endButton.Text=T 'Завершить сессию' 'Finish session'
    $historyButton.Text=T 'История сессий' 'Session history'
    $exportButton.Text=T 'Экспорт CSV' 'Export CSV'
    $voiceButton.Text=if($script:voiceEnabled){T 'Голос: вкл' 'Voice: on'}else{T 'Голос: выкл' 'Voice: off'}
    $bestHeader.Text=T 'ЛУЧШИЙ ПЛЕЙ СЕССИИ' 'BEST PLAY THIS SESSION'
    $bestEmpty.Text=T 'Твой лучший плей появится здесь ♡' 'Your best play will appear here ♡'
    $section.Text=T 'СКОРЫ СЕССИИ' 'SESSION SCORES'
    $emptyLabel.Text=T 'Пока нет скоров. Пройди карту — результат появится здесь.' 'No scores yet. Finish a beatmap to see your result here.'
    $hint.Text=T 'pp карт — расчёт tosu. Прирост профиля обновляется отдельно.' 'Play pp is calculated by tosu. Profile pp updates separately.'
    $status.Text=T 'Подключение к tosu…' 'Connecting to tosu…'
    $languageButton.Text=if($script:language -eq 'en'){'Русский'}else{'English'}
    $settingsButton.Text=T 'Оформление / OBS' 'Appearance / OBS'
    if($noticePanel.Visible){$noticePanel.Visible=$false}
    Refresh-View
}
$languageButton=New-Object SessionButton
$languageButton.Location=New-Object Drawing.Point(920,40);$languageButton.Size=New-Object Drawing.Size(155,38);$languageButton.Anchor='Top,Right'
$languageButton.Add_Click({$script:language=if($script:language -eq 'ru'){'en'}else{'ru'};Save-Settings;Apply-Language})
$form.Controls.Add($languageButton)
$languageButton.Location=New-Object Drawing.Point(940,30);$languageButton.Size=New-Object Drawing.Size(135,32)
$settingsButton=New-Object SessionButton;$settingsButton.Location=New-Object Drawing.Point(870,72);$settingsButton.Size=New-Object Drawing.Size(205,34);$settingsButton.Anchor='Top,Right'
$settingsButton.Add_Click({Show-AppearanceSettings});$form.Controls.Add($settingsButton)
Apply-DesktopStyle
Apply-Language
New-Session
try{Sync-Overlay}catch{$script:overlayEnabled=$false;$hint.Text=T 'Оверлей не запущен. Включи его в настройках OBS.' 'Overlay could not start. Enable it in OBS settings.'}
$script:feed.Start('ws://127.0.0.1:24050/websocket/v2')
$timer.Start()
[void]$form.ShowDialog()
