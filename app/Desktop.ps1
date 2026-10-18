$script:appRoot=$PSScriptRoot
$script:fontName='Comic Sans MS';$script:fontChosen=$false
$script:theme='rose';$script:backgroundId='cafe';$script:customBackgroundPath=''
$script:backgroundDim=67;$script:mascotEnabled=$true;$script:animationsEnabled=$true
$script:compactCards=$false;$script:overlayEnabled=$false;$script:overlayServer=$null
$script:overlayRecentEnabled=$true;$script:overlayRecentCount=3;$script:overlayBestEnabled=$true
$script:overlayFontName='';$script:overlayAnimation='slide';$script:overlayCardSize='normal';$script:overlayWidth=720;$script:overlayOpacity=89;$script:overlayShowStats=$true
$script:bestIncludeUnranked=$true
$script:historyMinPlays=3
$script:historyMetadata=@{}
$script:historyDirection='horizontal'
$script:overlaySpeed=100;$script:overlayTheme='app'
$script:animationKeys=@('none','slide','fade','pop','rise','bounce','flip','wipe')
$script:themeKeys=@('rose','ocean','lavender','mint','sunset','midnight')
$script:lastOverlayUpdate=[datetime]::MinValue
$installedFonts=New-Object Drawing.Text.InstalledFontCollection
$script:fontChoices=@(@('Comic Sans MS','Segoe UI','Calibri','Arial','Trebuchet MS','Verdana','Tahoma','Georgia','Consolas','Times New Roman','Segoe Print','Segoe Script','Candara','Corbel','Gabriola','Century Gothic','Bahnschrift','Franklin Gothic Medium')+@($installedFonts.Families.Name|Sort-Object)|Where-Object {$installedFonts.Families.Name -contains $_}|Select-Object -Unique)
$installedFonts.Dispose()
if([IO.File]::Exists($script:settingsPath)){
    try{$prefs=[IO.File]::ReadAllText($script:settingsPath)|ConvertFrom-Json
        foreach($name in @('fontName','fontChosen','theme','backgroundId','customBackgroundPath','backgroundDim','mascotEnabled','animationsEnabled','compactCards','overlayEnabled','overlayRecentEnabled','overlayRecentCount','overlayBestEnabled','overlayFontName','overlayAnimation','overlayCardSize','overlayWidth','overlayOpacity','overlayShowStats','overlaySpeed','overlayTheme','historyDirection','historyMinPlays','bestIncludeUnranked')){
            if($null -ne $prefs.$name){Set-Variable -Scope Script -Name $name -Value $prefs.$name}
        }
    }catch{}
}
if($script:fontChoices -notcontains $script:fontName){$script:fontName=$script:fontChoices[0]}
if($script:theme -notin $script:themeKeys){$script:theme='rose'}
if($script:backgroundId -notin @('cafe','lake','room','none','custom')){$script:backgroundId='cafe'}
$script:backgroundDim=[math]::Max(0,[math]::Min(90,[int]$script:backgroundDim))
$script:overlayRecentCount=[math]::Max(0,[math]::Min(5,[int]$script:overlayRecentCount))
if(!$script:overlayRecentEnabled){$script:overlayRecentCount=0}
if($script:overlayAnimation -notin $script:animationKeys){$script:overlayAnimation='slide'}
if($script:overlayCardSize -notin @('compact','normal','large')){$script:overlayCardSize='normal'}
if($script:overlayFontName -and $script:fontChoices -notcontains $script:overlayFontName){$script:overlayFontName=''}
$script:overlayWidth=[math]::Max(600,[math]::Min(1200,[int]$script:overlayWidth))
$script:overlayOpacity=[math]::Max(0,[math]::Min(100,[int]$script:overlayOpacity))
$script:overlaySpeed=[math]::Max(25,[math]::Min(300,[int]$script:overlaySpeed))
if($script:overlayTheme -notin (@('app')+$script:themeKeys)){$script:overlayTheme='app'}
function Get-ThemeAccent($key){switch($key){'ocean'{[Drawing.Color]::FromArgb(87,192,218)}'lavender'{[Drawing.Color]::FromArgb(178,146,235)}'mint'{[Drawing.Color]::FromArgb(110,222,181)}'sunset'{[Drawing.Color]::FromArgb(255,172,112)}'midnight'{[Drawing.Color]::FromArgb(127,154,255)}default{[Drawing.Color]::FromArgb(239,105,164)}}}
if($script:historyDirection -notin @('horizontal','vertical')){$script:historyDirection='horizontal'}
$script:historyMinPlays=[math]::Max(1,[math]::Min(100,[int]$script:historyMinPlays))
function Get-BeatmapStatus($map){
    $name=[string]$map.status.name
    if($name){return $name.ToLowerInvariant()}
    if($null -ne $map.status.number){switch([int]$map.status.number){4{return 'ranked'}5{return 'approved'}6{return 'qualified'}7{return 'loved'}1{return 'notsubmitted'}2{return 'pending'}}}
    return 'unknown'
}
function Get-SessionBest($plays){
    $eligible=if($script:bestIncludeUnranked){@($plays)}else{@($plays|Where-Object {$_.mapStatus -in @('ranked','approved')})}
    return $eligible|Sort-Object pp -Descending|Select-Object -First 1
}
function Dialog-Label($parent,$text,$x,$y,$width,$height,$size=11){
    $label=New-Object Windows.Forms.Label;$label.Text=$text;$label.Location=New-Object Drawing.Point($x,$y);$label.Size=New-Object Drawing.Size($width,$height)
    $label.Font=New-Object Drawing.Font($script:fontName,$size);$label.ForeColor=[Drawing.Color]::White;$parent.Controls.Add($label);return $label
}
function Dialog-Button($parent,$text,$x,$y,$width,$handler){
    $button=New-Object SessionButton;$button.Text=$text;$button.Location=New-Object Drawing.Point($x,$y);$button.Size=New-Object Drawing.Size($width,40)
    $button.Add_Click($handler);$parent.Controls.Add($button);return $button
}
function Dialog-Form($title,$width,$height){
    $dialog=New-Object SessionForm;$dialog.Text=$title;$dialog.ClientSize=New-Object Drawing.Size($width,$height)
    $dialog.BackColor=[Drawing.Color]::FromArgb(23,20,29);$dialog.ForeColor=[Drawing.Color]::White
    $dialog.Font=New-Object Drawing.Font($script:fontName,10);$dialog.StartPosition='CenterParent';[SessionTheme]::RoundWindow($dialog);return $dialog
}
function Font-Combo($parent,$x,$y,$width){
    $combo=New-Object Windows.Forms.ComboBox;$combo.Location=New-Object Drawing.Point($x,$y);$combo.Size=New-Object Drawing.Size($width,32);$combo.DropDownStyle='DropDownList'
    foreach($name in $script:fontChoices){[void]$combo.Items.Add($name)}
    $combo.SelectedItem=$script:fontName;$parent.Controls.Add($combo);return $combo
}
function Select-FirstFont {
    $dialog=Dialog-Form (T 'Выбери шрифт' 'Choose your font') 620 330
    [void](Dialog-Label $dialog (T 'Какой шрифт тебе нравится?' 'Which font do you like?') 25 25 570 40 17)
    $combo=Font-Combo $dialog 25 80 570
    $preview=Dialog-Label $dialog "osu! session tracker ♡`r`nПример текста / Sample text · 200.00 pp" 25 135 570 100 17
    $combo.Add_SelectedIndexChanged({$preview.Font=New-Object Drawing.Font([string]$combo.SelectedItem,17)})
    $save=Dialog-Button $dialog (T 'Продолжить' 'Continue') 385 265 210 {$script:fontName=[string]$combo.SelectedItem;$script:fontChosen=$true;Save-Settings;$dialog.DialogResult='OK'}
    $save.Primary=$true;$dialog.AcceptButton=$save
    $result=$dialog.ShowDialog();$dialog.Dispose();return ($result -eq 'OK')
}
function Get-MenuBackgroundPath($id,$custom){
    switch($id){
        'cafe'{return Join-Path $script:appRoot 'assets/menu-background.png'}
        'lake'{return Join-Path $script:appRoot 'assets/gallery-lake.png'}
        'room'{return Join-Path $script:appRoot 'assets/gallery-room.png'}
        'custom'{
            if(!$custom){return $null}
            $root=[IO.Path]::GetFullPath($script:appRoot)+[IO.Path]::DirectorySeparatorChar
            $path=[IO.Path]::GetFullPath((Join-Path $script:appRoot $custom))
            if($path.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){return $path}
        }
    }
    return $null
}
function Import-MenuBackground([string]$path){
    if((Get-Item -LiteralPath $path).Length -gt 26214400){throw (T 'Изображение должно быть меньше 25 МБ.' 'Please choose an image smaller than 25 MB.')}
    $source=[Drawing.Image]::FromFile($path)
    try{
        if($source.Width -gt 16000 -or $source.Height -gt 16000){throw (T 'Слишком большое разрешение изображения.' 'Image dimensions are too large.')}
        $scale=[math]::Min(1,2048/[math]::Max($source.Width,$source.Height))
        $bitmap=New-Object Drawing.Bitmap([math]::Max(1,[int]($source.Width*$scale)),[math]::Max(1,[int]($source.Height*$scale)))
        try{$graphics=[Drawing.Graphics]::FromImage($bitmap);try{$graphics.InterpolationMode='HighQualityBicubic';$graphics.DrawImage($source,0,0,$bitmap.Width,$bitmap.Height)}finally{$graphics.Dispose()}
            $dir=Join-Path $script:appRoot 'user-backgrounds';[IO.Directory]::CreateDirectory($dir)|Out-Null
            $relative='user-backgrounds/'+[guid]::NewGuid().ToString()+'.jpg'
            $bitmap.Save((Join-Path $script:appRoot $relative),[Drawing.Imaging.ImageFormat]::Jpeg)
            return $relative
        }finally{$bitmap.Dispose()}
    }finally{$source.Dispose()}
}
function Apply-DesktopStyle {
    $accent=Get-ThemeAccent $script:theme
    [SessionTheme]::Accent=$accent
    [SessionTheme]::PanelColor=switch($script:theme){'ocean'{[Drawing.Color]::FromArgb(26,40,52)}'lavender'{[Drawing.Color]::FromArgb(38,32,56)}'mint'{[Drawing.Color]::FromArgb(24,48,43)}'sunset'{[Drawing.Color]::FromArgb(57,36,33)}'midnight'{[Drawing.Color]::FromArgb(26,32,55)}default{[Drawing.Color]::FromArgb(38,31,46)}}
    [SessionTheme]::CardColor=[SessionTheme]::PanelColor
    [SessionTheme]::FontName=$script:fontName;$script:uiFont=$script:fontName
    if(!$form){return}
    function Set-ControlFont($control){
        if($control.Font.FontFamily.Name -ne $script:fontName){$control.Font=New-Object Drawing.Font($script:fontName,$control.Font.Size,$control.Font.Style)}
        foreach($child in $control.Controls){Set-ControlFont $child}
    }
    Set-ControlFont $form
    $summary.BackColor=[SessionTheme]::PanelColor;$title.ForeColor=[Drawing.Color]::FromArgb(255,$accent)
    $bestHeader.ForeColor=[Drawing.Color]::FromArgb(255,$accent);$noticePanel.BackColor=[SessionTheme]::PanelColor
    $noticeTitle.ForeColor=[Drawing.Color]::FromArgb(255,$accent)
    $form.DimPercent=$script:backgroundDim
    $path=Get-MenuBackgroundPath $script:backgroundId $script:customBackgroundPath
    if($script:loadedWallpaperPath -ne $path){
        $image=$null
        if($path -and [IO.File]::Exists($path)){$source=[Drawing.Image]::FromFile($path);try{$image=New-Object Drawing.Bitmap($source)}finally{$source.Dispose()}}
        $old=$form.Wallpaper;$form.Wallpaper=$image;if($old){$old.Dispose()};$script:loadedWallpaperPath=$path
    }
    $height=if($script:compactCards){90}else{110}
    $list.ApplyCardStyle($script:fontName,$height,$script:animationsEnabled)
    $bestCards.ApplyCardStyle($script:fontName,$height,$false)
    if(!$script:mascotEnabled){$noticePanel.Visible=$false}
    $form.Invalidate($true)
}
function Convert-OverlayScore($play){
    if(!$play){return $null}
    $bg='';$mods=@()
    if($script:overlayServer){
        $bg=$script:overlayServer.RegisterImage([string]$play.background)
        foreach($mod in [ScoreCards]::ParseMods([string]$play.mods)){
            $mods+=@{name=$mod;image=$script:overlayServer.RegisterImage((Join-Path $script:appRoot ('assets/mods/'+$mod+'.png')))}
        }
    }
    return @{fcPp=$play.fcPp;rate=$play.modRate;map=$play.map;pp=$play.pp;accuracy=$play.accuracy;combo=$play.combo;fc=[bool]$play.fc;rank=$play.rank;stars=$play.stars;hits=$play.hitText;time=$play.time;background=$bg;mods=@($mods)}
}
function Get-OverlayState {
    $s=$script:session
    $plays=if($s){@($s.plays)}else{@()}
    $best=Get-SessionBest $plays
    $gain=$null;if($s -and $null -ne $s.baseline -and $null -ne $s.latest){$gain=[math]::Round($s.latest-$s.baseline,2)}
    $seconds=0;if($s){$end=if($s.ended){[datetime]$s.ended}else{Get-Date};$seconds=[math]::Max(0,[int]($end-[datetime]$s.started).TotalSeconds)}
    $recent=@()
    if($script:overlayRecentEnabled){for($i=$plays.Count-1;$i -ge 0 -and $recent.Count -lt $script:overlayRecentCount;$i--){$recent+=Convert-OverlayScore $plays[$i]}}
    return @{animationSpeed=$script:overlaySpeed;theme=$(if($script:overlayTheme -eq 'app'){$script:theme}else{$script:overlayTheme});animation=$script:overlayAnimation;cardSize=$script:overlayCardSize;width=$script:overlayWidth;opacity=$script:overlayOpacity;showStats=$script:overlayShowStats;showRecent=($script:overlayRecentCount -gt 0);showBest=$script:overlayBestEnabled;recent=@($recent);best=$(if($script:overlayBestEnabled){Convert-OverlayScore $best}else{$null});animate=($script:overlayAnimation -ne 'none');language=$script:language;font=$(if($script:overlayFontName){$script:overlayFontName}else{$script:fontName});accent=('#{0:X2}{1:X2}{2:X2}' -f $(if($script:overlayTheme -eq 'app'){[SessionTheme]::Accent.R}else{(Get-ThemeAccent $script:overlayTheme).R}),$(if($script:overlayTheme -eq 'app'){[SessionTheme]::Accent.G}else{(Get-ThemeAccent $script:overlayTheme).G}),$(if($script:overlayTheme -eq 'app'){[SessionTheme]::Accent.B}else{(Get-ThemeAccent $script:overlayTheme).B}));gain=$gain;fc=@($plays|Where-Object fc).Count;plays=$plays.Count;bestPp=$(if($best){$best.pp}else{$null});bestMap=$(if($best){$best.map}else{''});seconds=$seconds;ended=[bool]($s -and $s.ended)}
}
function Sync-Overlay {
    if(!$script:overlayEnabled){if($script:overlayServer){$script:overlayServer.Dispose();$script:overlayServer=$null};return}
    if(!$script:overlayServer){
        $server=New-Object ObsOverlay
        try{$server.Start((Join-Path $script:appRoot 'assets/overlay.html'));$script:overlayServer=$server}catch{$server.Dispose();throw}
    }
    $script:overlayServer.SetState((Get-OverlayState|ConvertTo-Json -Depth 7 -Compress))
}
function Tick-Overlay {
    if($script:overlayEnabled -and ((Get-Date)-$script:lastOverlayUpdate).TotalMilliseconds -ge 500){$script:lastOverlayUpdate=Get-Date;Sync-Overlay}
}
function New-DemoScore($server,$index=0){
    $background=$server.RegisterImage((Join-Path $script:appRoot 'assets/gallery-lake.png'))
    $mods=@(@{name='HD';image=$server.RegisterImage((Join-Path $script:appRoot 'assets/mods/HD.png'))},@{name='DT';image=$server.RegisterImage((Join-Path $script:appRoot 'assets/mods/DT.png'))})
    return @{map="Demo artist - Demo map $($index+1) [Insane]";pp=(250+$index*12.5);fcPp=(270+$index*12.5);accuracy=99.25;combo=1250;fc=$true;rank='S';stars=6.25;hits='300: 1000   100: 12   50: 0   MISS: 0';time=(Get-Date).AddMinutes(-$index).ToString('o');background=$background;mods=$mods}
}
function Get-ObsCanvasSize($width,$size,$count,$best,$stats){
    $height=switch($size){'compact'{90}'large'{145}default{110}}
    return [pscustomobject]@{width=([int]$width+40);height=(110+$(if($stats){90}else{0})+$(if($best){$height+45}else{0})+$(if($count -gt 0){$count*($height+8)+45}else{0}))}
}
function Show-AppearanceSettings {
    $dialog=Dialog-Form (T 'Настройки и предпросмотр · 2.2' 'Settings & preview · 2.2') 1240 880
    $dialog.FormBorderStyle='FixedDialog';$dialog.MaximizeBox=$false
    $tabs=New-Object SettingsTabs;$tabs.SetBounds(20,100,1200,680);$tabs.Anchor='Top,Bottom,Left,Right';$dialog.Controls.Add($tabs)
    $appearance=New-Object Windows.Forms.TabPage;$appearance.Text=T 'Оформление' 'Appearance';$appearance.BackColor=[Drawing.Color]::FromArgb(23,20,29);$tabs.TabPages.Add($appearance)
    $obs=New-Object Windows.Forms.TabPage;$obs.Text='OBS';$obs.BackColor=$appearance.BackColor;$tabs.TabPages.Add($obs)
    $sessionOptions=New-Object Windows.Forms.TabPage;$sessionOptions.Text=T 'Сессии' 'Sessions';$sessionOptions.BackColor=$appearance.BackColor;$tabs.TabPages.Add($sessionOptions)
    $draft=@{backgroundId=$script:backgroundId;customPath=$script:customBackgroundPath;previewServer=$null;previewToken=''}
    function Settings-Combo($parent,$label,$y,$values,$selected=0){
        [void](Dialog-Label $parent $label 20 $y 550 25 10)
        $c=New-Object SettingsCombo;$c.SetBounds(20,($y+28),550,32);$c.DropDownStyle='DropDownList';[void]$c.Items.AddRange([object[]]$values);$c.SelectedIndex=$selected;$parent.Controls.Add($c);return $c
    }
    function Settings-Check($parent,$text,$y,$value){$c=New-Object SettingsToggle;$c.Text=$text;$c.SetBounds(20,$y,550,28);$c.Checked=$value;$parent.Controls.Add($c);return $c}
    function Settings-Number($parent,$text,$y,$min,$max,$value,$step=1){[void](Dialog-Label $parent $text 20 $y 420 28 10);$n=New-Object SettingsNumber;$n.SetBounds(455,$y,115,30);$n.Minimum=$min;$n.Maximum=$max;$n.Increment=$step;$n.Value=$value;$parent.Controls.Add($n);return $n}
    $font=Settings-Combo $appearance (T 'Шрифт программы' 'App font') 15 $script:fontChoices ($script:fontChoices.IndexOf($script:fontName))
    $themes=Settings-Combo $appearance (T 'Тема' 'Theme') 90 @((T 'Розовая' 'Rose'),(T 'Океан' 'Ocean'),(T 'Лаванда' 'Lavender'),(T 'Мята' 'Mint'),(T 'Закат' 'Sunset'),(T 'Полночь' 'Midnight')) ($script:themeKeys.IndexOf($script:theme))
    $gallery=Settings-Combo $appearance (T 'Фон' 'Wallpaper') 165 @((T 'Вечернее кафе' 'Twilight café'),(T 'Ночное озеро' 'Moonlit lake'),(T 'Уютная комната' 'Cozy room'),(T 'Без фона' 'No wallpaper'),(T 'Моё изображение' 'My image')) (@('cafe','lake','room','none','custom').IndexOf($script:backgroundId))
    [void](Dialog-Button $appearance (T 'Выбрать своё изображение…' 'Choose your image…') 20 240 550 {
        $open=New-Object Windows.Forms.OpenFileDialog;$open.Filter='Images (*.png;*.jpg;*.jpeg;*.bmp)|*.png;*.jpg;*.jpeg;*.bmp'
        if($open.ShowDialog() -eq 'OK'){try{$draft.customPath=Import-MenuBackground $open.FileName;$gallery.SelectedIndex=4;& $updateAppearance}catch{[void][Windows.Forms.MessageBox]::Show($_.Exception.Message)}};$open.Dispose()
    })
    $dim=Settings-Number $appearance (T 'Затемнение фона, %' 'Background dimming, %') 295 0 90 $script:backgroundDim 5
    $mascotCheck=Settings-Check $appearance (T 'Показывать маскота' 'Show mascot') 340 $script:mascotEnabled
    $voiceCheck=Settings-Check $appearance (T 'Японское приветствие' 'Japanese voice greeting') 375 $script:voiceEnabled
    [void](Dialog-Button $appearance (T 'Послушать приветствие' 'Preview voice greeting') 20 415 550 {[void][MascotAudio]::Play((Join-Path $script:appRoot 'assets/welcome-ja.wav'))})
    $animationCheck=Settings-Check $appearance (T 'Анимация новых скоров в программе' 'Animate new scores in the app') 470 $script:animationsEnabled
    $compactCheck=Settings-Check $appearance (T 'Компактные карточки в программе' 'Compact cards in the app') 505 $script:compactCards
    $archiveDirection=Settings-Combo $appearance (T 'Архив · направление «Все скоры»' 'Archive · All scores direction') 550 @((T 'Горизонтально · слева направо' 'Horizontal · left to right'),(T 'Вертикально · сверху вниз' 'Vertical · top to bottom')) (@('horizontal','vertical').IndexOf($script:historyDirection))
    $archiveDirection.Name='HistoryDirection'
    $archivePreview=New-Object ArchiveLayoutPreview;$archivePreview.SetBounds(600,625,565,40);$archivePreview.Name='ArchiveLayoutPreview';$appearance.Controls.Add($archivePreview)
    $archiveMinimum=Settings-Number $appearance (T 'Архив · минимум скоров в сессии' 'Archive · minimum scores per session') 625 1 100 $script:historyMinPlays 1
    $archiveMinimum.Name='HistoryMinPlays'
    $archiveMinimumPreview=Dialog-Label $appearance '' 20 660 550 20 9
    $minimumPreview={$archiveMinimumPreview.Text=T ("В архив: от $([int]$archiveMinimum.Value) скоров. Пустые не сохраняются.") ("Archive: $([int]$archiveMinimum.Value)+ scores. Empty sessions are not saved.")}
    $archiveMinimum.Add_ValueChanged($minimumPreview);& $minimumPreview
    $archiveControls=@($appearance.Controls|Where-Object {$_.Top -ge 550})
    foreach($control in $archiveControls){$control.Top-=530;$sessionOptions.Controls.Add($control)}
    $includeUnranked=Settings-Check $sessionOptions (T 'Loved / unranked могут быть лучшим скором' 'Allow loved / unranked as session best') 185 $script:bestIncludeUnranked
    $includeUnranked.Name='BestIncludeUnranked'
    $bestRulePreview=Dialog-Label $sessionOptions '' 20 230 550 110 11
    $updateBestRule={$bestRulePreview.Text=if($includeUnranked.Checked){T 'Лучший скор: максимальные pp среди всех карт.' 'Session best: highest pp across all maps.'}else{T 'Лучший скор: только Ranked / Approved. Loved, Unranked и неизвестный статус остаются в списке скоров.' 'Session best: Ranked / Approved only. Loved, unranked and unknown status remain in the score list.'}}
    $includeUnranked.Add_CheckedChanged($updateBestRule);& $updateBestRule
    [void](Dialog-Label $sessionOptions (T 'Правило применяется к программе, архиву, PNG и OBS. Изменения — после «Применить».' 'Applies to the app, archive, PNG and OBS. Changes take effect after Apply.') 600 195 565 120 12)
    $appPreview=New-Object SettingsPreview;$appPreview.SetBounds(600,50,565,560);$appPreview.Anchor='Top,Left';$appPreview.SetMascot((Join-Path $script:appRoot 'assets/mascot.png'));$appearance.Controls.Add($appPreview)
    $obsCheck=Settings-Check $obs (T 'Включить оверлей OBS / TikTok' 'Enable OBS / TikTok overlay') 15 $script:overlayEnabled
    $statsCheck=Settings-Check $obs (T 'Показывать счётчики сессии' 'Show session statistics') 50 $script:overlayShowStats
    $bestCheck=Settings-Check $obs (T 'Показывать лучший скор сессии' 'Show session best score') 85 $script:overlayBestEnabled
    $recentCount=Settings-Number $obs (T 'Последние скоры · 0 = скрыть' 'Recent scores · 0 = hide') 125 0 5 $script:overlayRecentCount
    $obsFonts=@((T 'Как в программе' 'Same as the app'))+@($script:fontChoices)
    $obsFontIndex=if($script:overlayFontName){1+$script:fontChoices.IndexOf($script:overlayFontName)}else{0}
    $obsFont=Settings-Combo $obs (T 'Шрифт OBS · независимо от программы' 'OBS font · independent from app') 170 $obsFonts $obsFontIndex
    $obsAnimation=Settings-Combo $obs (T 'Анимация новых карточек' 'New card animation') 245 @((T 'Нет' 'None'),(T 'Сдвиг' 'Slide'),(T 'Появление' 'Fade'),(T 'Увеличение' 'Pop'),(T 'Снизу вверх' 'Rise'),(T 'Пружина' 'Bounce'),(T 'Поворот' 'Flip'),(T 'Раскрытие' 'Wipe')) ($script:animationKeys.IndexOf($script:overlayAnimation))
    $obsSpeed=Settings-Number $obs (T 'Скорость анимации, % · 100 = обычная' 'Animation speed, % · 100 = normal') 320 25 300 $script:overlaySpeed 25
    $obsTheme=Settings-Combo $obs (T 'Тема OBS' 'OBS theme') 365 @((T 'Как в программе' 'Same as the app'),(T 'Розовая' 'Rose'),(T 'Океан' 'Ocean'),(T 'Лаванда' 'Lavender'),(T 'Мята' 'Mint'),(T 'Закат' 'Sunset'),(T 'Полночь' 'Midnight')) ((@('app')+$script:themeKeys).IndexOf($script:overlayTheme))
    $obsSize=Settings-Combo $obs (T 'Размер карточек' 'Card size') 445 @((T 'Компактный · 90 px' 'Compact · 90 px'),(T 'Обычный · 110 px' 'Normal · 110 px'),(T 'Крупный · 145 px' 'Large · 145 px')) (@('compact','normal','large').IndexOf($script:overlayCardSize))
    $obsWidth=Settings-Number $obs (T 'Ширина панели, px' 'Panel width, px') 525 600 1200 $script:overlayWidth 20
    $obsOpacity=Settings-Number $obs (T 'Непрозрачность фона, %' 'Panel background opacity, %') 570 0 100 $script:overlayOpacity 5
    [void](Dialog-Button $obs (T 'Точный предпросмотр в браузере' 'Exact browser preview') 20 620 550 {
        try{if(!$draft.previewServer){$draft.previewServer=New-Object ObsOverlay;$draft.previewServer.StartPreview((Join-Path $script:appRoot 'assets/overlay.html'))};& $syncPreview $true;Start-Process $draft.previewServer.Url}catch{[void][Windows.Forms.MessageBox]::Show($_.Exception.Message)}
    })
    [void](Dialog-Button $obs (T 'Повторить анимацию' 'Replay animation') 20 670 550 {$obsPreview.Replay();if($draft.previewServer){& $syncPreview $true}})
    $obsInfo=Dialog-Label $obs '' 20 720 550 50 10
    $obsPreview=New-Object SettingsPreview;$obsPreview.ObsMode=$true;$obsPreview.SetBounds(600,50,565,560);$obsPreview.Anchor='Top,Left';$obs.Controls.Add($obsPreview)
    $previewLabel=Dialog-Label $obs (T 'Демо · для точных анимаций открой браузерный предпросмотр' 'Demo · open the browser preview for exact animations') 600 620 565 25 9
    $obsSpeed.Name='ObsSpeed';$obsTheme.Name='ObsTheme'
    $font.Name='AppFont';$themes.Name='AppTheme';$gallery.Name='AppWallpaper';$dim.Name='AppDim';$mascotCheck.Name='ShowMascot';$voiceCheck.Name='Voice';$animationCheck.Name='AppAnimation';$compactCheck.Name='CompactCards'
    $tabs.Name='SettingsTabs';$recentCount.Name='ObsRecentCount';$obsFont.Name='ObsFont';$obsAnimation.Name='ObsAnimation';$obsSize.Name='ObsSize';$obsWidth.Name='ObsWidth';$obsOpacity.Name='ObsOpacity';$bestCheck.Name='ObsBest';$statsCheck.Name='ObsStats';$obsCheck.Name='ObsEnabled';$appPreview.Name='AppearancePreview';$obsPreview.Name='ObsPreview'
    $updateAppearance={
        $archivePreview.Vertical=($archiveDirection.SelectedIndex -eq 1);$archivePreview.Invalidate()
        $draft.backgroundId=@('cafe','lake','room','none','custom')[$gallery.SelectedIndex]
        $appPreview.PreviewFont=[string]$font.SelectedItem;$appPreview.Dim=[int]$dim.Value;$appPreview.ShowMascot=$mascotCheck.Checked;$appPreview.Compact=$compactCheck.Checked
        $appPreview.AccentColor=Get-ThemeAccent $script:themeKeys[$themes.SelectedIndex]
        $appPreview.SetWallpaper((Get-MenuBackgroundPath $draft.backgroundId $draft.customPath));$appPreview.Invalidate();if($animationCheck.Checked){$appPreview.Replay()}else{$appPreview.StopPreview()}
        if($obsPreview){& $updateObs}
    }
    $syncPreview={param($replay=$false)
        if(!$draft.previewServer){return}
        $recent=@();for($i=0;$i -lt [int]$recentCount.Value;$i++){$recent+=New-DemoScore $draft.previewServer $i}
        $demoBest=New-DemoScore $draft.previewServer 8
        $state=@{animationSpeed=[int]$obsSpeed.Value;theme=$(if($obsTheme.SelectedIndex -eq 0){$script:themeKeys[$themes.SelectedIndex]}else{$script:themeKeys[$obsTheme.SelectedIndex-1]});preview=$true;previewToken=$(if($replay){[guid]::NewGuid().ToString()}else{$draft.previewToken});language=$script:language;font=$(if($obsFont.SelectedIndex -gt 0){[string]$obsFont.SelectedItem}else{[string]$font.SelectedItem});accent=('#{0:X2}{1:X2}{2:X2}' -f $obsPreview.AccentColor.R,$obsPreview.AccentColor.G,$obsPreview.AccentColor.B);gain=23.35;fc=3;plays=8;bestPp=$demoBest.pp;best=$demoBest;recent=@($recent);seconds=2525;ended=$false;animate=$true;animation=$script:animationKeys[$obsAnimation.SelectedIndex];cardSize=@('compact','normal','large')[$obsSize.SelectedIndex];width=[int]$obsWidth.Value;opacity=[int]$obsOpacity.Value;showStats=$statsCheck.Checked;showBest=$bestCheck.Checked;showRecent=($recentCount.Value -gt 0)}
        $draft.previewToken=$state.previewToken;$draft.previewServer.SetState(($state|ConvertTo-Json -Depth 7 -Compress))
    }
    $updateObs={
        $obsPreview.PreviewFont=if($obsFont.SelectedIndex -gt 0){[string]$obsFont.SelectedItem}else{[string]$font.SelectedItem}
        $obsPreview.AccentColor=if($obsTheme.SelectedIndex -eq 0){$appPreview.AccentColor}else{Get-ThemeAccent $script:themeKeys[$obsTheme.SelectedIndex-1]};$obsPreview.PanelColor=switch((@('app')+$script:themeKeys)[$obsTheme.SelectedIndex]){'mint'{[Drawing.Color]::FromArgb(18,35,33)}'sunset'{[Drawing.Color]::FromArgb(40,27,28)}'midnight'{[Drawing.Color]::FromArgb(19,23,42)}'ocean'{[Drawing.Color]::FromArgb(21,32,43)}'lavender'{[Drawing.Color]::FromArgb(30,25,43)}default{[Drawing.Color]::FromArgb(23,19,32)}};$obsPreview.AnimationSpeed=[int]$obsSpeed.Value;$obsPreview.RecentCount=[int]$recentCount.Value;$obsPreview.ShowBest=$bestCheck.Checked;$obsPreview.ShowStats=$statsCheck.Checked
        $obsPreview.CardHeight=@(90,110,145)[$obsSize.SelectedIndex];$obsPreview.OverlayWidth=[int]$obsWidth.Value;$obsPreview.PanelOpacity=[int]$obsOpacity.Value;$obsPreview.Animation=$script:animationKeys[$obsAnimation.SelectedIndex]
        $obsPreview.SetWallpaper((Join-Path $script:appRoot 'assets/gallery-lake.png'));$obsPreview.Invalidate();$obsPreview.Replay()
        $canvas=Get-ObsCanvasSize $obsWidth.Value (@('compact','normal','large')[$obsSize.SelectedIndex]) $recentCount.Value $bestCheck.Checked $statsCheck.Checked
        $obsInfo.Text=(T 'Размер источника OBS: ' 'OBS source size: ')+"$($canvas.width) × $($canvas.height)"+"`r`n"+(T 'Предпросмотр не меняет виджет на стриме.' 'Preview does not change your live overlay.')
        & $syncPreview $true
    }
    foreach($c in @($font,$themes,$gallery,$archiveDirection)){$c.Add_SelectedIndexChanged($updateAppearance)}
    $dim.Add_ValueChanged($updateAppearance);foreach($c in @($mascotCheck,$compactCheck,$animationCheck)){$c.Add_CheckedChanged($updateAppearance)}
    foreach($c in @($obsFont,$obsAnimation,$obsSize,$obsTheme)){$c.Add_SelectedIndexChanged($updateObs)}
    foreach($c in @($obsWidth,$obsOpacity,$recentCount,$obsSpeed)){$c.Add_ValueChanged($updateObs)}
    foreach($c in @($statsCheck,$bestCheck)){$c.Add_CheckedChanged($updateObs)}
    $apply={
        $script:bestIncludeUnranked=$includeUnranked.Checked;$script:cardsKey=$null;$script:historyMinPlays=[int]$archiveMinimum.Value;$script:historyDirection=@('horizontal','vertical')[$archiveDirection.SelectedIndex];$script:fontName=[string]$font.SelectedItem;$script:fontChosen=$true;$script:theme=$script:themeKeys[$themes.SelectedIndex]
        $script:backgroundId=$draft.backgroundId;$script:customBackgroundPath=$draft.customPath;$script:backgroundDim=[int]$dim.Value
        $script:mascotEnabled=$mascotCheck.Checked;$script:voiceEnabled=$voiceCheck.Checked;$script:animationsEnabled=$animationCheck.Checked;$script:compactCards=$compactCheck.Checked
        $script:overlayEnabled=$obsCheck.Checked;$script:overlayShowStats=$statsCheck.Checked;$script:overlayBestEnabled=$bestCheck.Checked;$script:overlayRecentCount=[int]$recentCount.Value;$script:overlayRecentEnabled=($recentCount.Value -gt 0)
        $script:overlaySpeed=[int]$obsSpeed.Value;$script:overlayTheme=(@('app')+$script:themeKeys)[$obsTheme.SelectedIndex]
        $script:overlayFontName=if($obsFont.SelectedIndex -gt 0){[string]$obsFont.SelectedItem}else{''};$script:overlayAnimation=$script:animationKeys[$obsAnimation.SelectedIndex]
        $script:overlayCardSize=@('compact','normal','large')[$obsSize.SelectedIndex];$script:overlayWidth=[int]$obsWidth.Value;$script:overlayOpacity=[int]$obsOpacity.Value
        if(!$script:voiceEnabled){[MascotAudio]::Stop()};Apply-DesktopStyle;Apply-Language;Refresh-View
        try{Sync-Overlay}catch{$script:overlayEnabled=$false;$obsCheck.Checked=$false;[void][Windows.Forms.MessageBox]::Show($_.Exception.Message)}
        Save-Settings
        $saveInfo.Text=T 'Сохранено. Настройки OBS применены.' 'Saved. OBS settings applied.'
    }
    [void](Dialog-Button $dialog (T 'Скопировать URL OBS' 'Copy OBS URL') 20 805 210 {if($script:overlayServer){[Windows.Forms.Clipboard]::SetText($script:overlayServer.Url);$saveInfo.Text=$script:overlayServer.Url}else{$saveInfo.Text=T 'Сначала включи OBS и нажми «Применить».' 'Enable OBS and click Apply first.'}})
    [void](Dialog-Button $dialog (T 'Ссылка TikTok' 'Copy TikTok URL') 245 805 210 {if($script:overlayServer){[Windows.Forms.Clipboard]::SetText($script:overlayServer.TikTokUrl);$saveInfo.Text=$script:overlayServer.TikTokUrl}else{$saveInfo.Text=T 'Включи оверлей и нажми «Применить».' 'Enable the overlay and click Apply first.'}})
    $saveInfo=Dialog-Label $dialog '' 475 795 375 70 10
    $applyButton=Dialog-Button $dialog (T 'Применить' 'Apply') 875 805 160 $apply;$applyButton.Primary=$true
    [void](Dialog-Button $dialog (T 'Закрыть' 'Close') 1055 805 165 {$dialog.Close()})
    [void](Dialog-Label $dialog (T 'Настрой под себя' 'Make it yours') 25 15 630 35 21)
    $subtitle=Dialog-Label $dialog (T 'Оформление, OBS и живой предпросмотр — в одном месте.' 'Appearance, OBS and live previews — all in one place.') 25 55 630 30 10
    $subtitle.ForeColor=[Drawing.Color]::FromArgb(171,157,185)
    $appearanceNav=Dialog-Button $dialog (T 'Оформление' 'Appearance') 690 28 160 {$tabs.SelectedIndex=0}
    $obsNav=Dialog-Button $dialog 'OBS' 870 28 160 {$tabs.SelectedIndex=1}
    $sessionNav=Dialog-Button $dialog (T 'Сессии' 'Sessions') 1055 28 165 {$tabs.SelectedIndex=2}
    $appearanceNav.Name='AppearanceNav';$obsNav.Name='ObsNav';$sessionNav.Name='SessionsNav'
    $appearanceNav.BringToFront();$obsNav.BringToFront();$sessionNav.BringToFront()
    $appearanceNav.Primary=$true
    $tabs.Add_SelectedIndexChanged({$appearanceNav.Primary=($tabs.SelectedIndex -eq 0);$obsNav.Primary=($tabs.SelectedIndex -eq 1);$appearanceNav.Invalidate();$obsNav.Invalidate();$sessionNav.Primary=($tabs.SelectedIndex -eq 2);$sessionNav.Invalidate()})
    foreach($page in @($appearance,$obs)){
        $heading=Dialog-Label $page (T 'ЖИВОЙ ПРЕДПРОСМОТР' 'LIVE PREVIEW') 610 10 550 30 11
        $heading.ForeColor=[Drawing.Color]::FromArgb(191,171,211)
    }
    [SessionTheme]::Round($appPreview,18);[SessionTheme]::Round($obsPreview,18)
    function Settings-Section($page,$y,$height){
        $section=New-Object SettingsSection;$section.SetBounds(5,$y,575,$height)
        $children=@($page.Controls|Where-Object {$_.Left -lt 580 -and $_.Top -ge $y -and $_.Bottom -le ($y+$height)})
        $page.Controls.Add($section)
        foreach($child in $children){$child.Location=New-Object Drawing.Point(($child.Left-5),($child.Top-$y));$section.Controls.Add($child)}
        $section.SendToBack()
    }
    Settings-Section $appearance 0 160;Settings-Section $appearance 160 175;Settings-Section $appearance 335 210
    $obsScroll=New-Object Windows.Forms.Panel;$obsScroll.SetBounds(0,0,590,650);$obsScroll.AutoScroll=$true;$obsScroll.Name='ObsOptions'
    $leftControls=@($obs.Controls|Where-Object {$_.Left -lt 580});$obs.Controls.Add($obsScroll)
    foreach($control in $leftControls){$obsScroll.Controls.Add($control)}
    $obsScroll.AutoScrollMinSize=New-Object Drawing.Size(0,790)
    function Settings-Typography($parent){foreach($child in $parent.Controls){$oldFont=$child.Font;$child.Font=New-Object Drawing.Font('Segoe UI',$oldFont.Size,$oldFont.Style);Settings-Typography $child}}
    $dialog.Font=New-Object Drawing.Font('Segoe UI',11);Settings-Typography $dialog
    & $updateAppearance
    try{[void]$dialog.ShowDialog($form)}finally{if($draft.previewServer){$draft.previewServer.Dispose()};[MascotAudio]::Stop();$dialog.Dispose()}
}
function Get-HistoryIndex {
    $items=New-Object 'System.Collections.Generic.List[object]'
    if(![IO.Directory]::Exists($dataDir)){return @()}
    foreach($file in Get-ChildItem -LiteralPath $dataDir -Filter '*.json'){
        try{
            $stamp=$file.LastWriteTimeUtc.Ticks.ToString()+':'+$file.Length
            $metadata=$script:historyMetadata[$file.FullName]
            if(!$metadata -or $metadata.stamp -ne $stamp){
                $savedSession=[IO.File]::ReadAllText($file.FullName)|ConvertFrom-Json
                if(!$savedSession.started -or $null -eq $savedSession.plays){continue}
                $metadata=@{stamp=$stamp;date=[datetime]$savedSession.started;count=@($savedSession.plays).Count}
                $script:historyMetadata[$file.FullName]=$metadata
            }
            if($metadata.count -lt $script:historyMinPlays){continue}
            $date=$metadata.date
        }catch{continue}
        $items.Add([pscustomobject]@{label=$date.ToString('dd.MM.yyyy  HH:mm');path=$file.FullName;date=$date;day=$date.ToString('yyyy-MM-dd');month=$date.ToString('yyyy-MM')})
    }
    return @($items|Sort-Object date -Descending)
}
function Get-HistoryPeriods($index,$group){
    if($group -eq 'all'){return @([pscustomobject]@{key='all';label=(T 'Все даты' 'All dates')})}
    return @($index|Group-Object $group|Sort-Object Name -Descending|ForEach-Object {
        $date=$_.Group[0].date
        $label=if($group -eq 'day'){$date.ToString('dd.MM.yyyy')}else{$date.ToString('MMMM yyyy',[Globalization.CultureInfo]::GetCultureInfo($(if($script:language -eq 'ru'){'ru-RU'}else{'en-US'})))}
        [pscustomobject]@{key=$_.Name;label=$label+'  ·  '+$_.Count}
    })
}
function Show-SessionHistory {
    $window=Dialog-Form (T 'Архив сессий · 2.2' 'Session archive · 2.2') 1280 850
    $window.FormBorderStyle='FixedDialog';$window.MaximizeBox=$false
    [void](Dialog-Label $window (T 'АРХИВ СЕССИЙ' 'SESSION ARCHIVE') 25 15 600 34 20)
    [void](Dialog-Label $window (T '1 · Выбери период' '1 · Choose a period') 25 60 300 25 10)
    [void](Dialog-Label $window (T 'Период' 'Period') 25 135 290 25 10)
    [void](Dialog-Label $window (T '2 · Сессии в этом периоде' '2 · Sessions in this period') 25 210 300 25 10)
    function History-Combo($x,$width){$c=New-Object SettingsCombo;$c.SetBounds($x,90,$width,32);$c.DropDownStyle='DropDownList';$window.Controls.Add($c);return $c}
    $group=History-Combo 25 290;[void]$group.Items.AddRange([object[]]@((T 'По дням' 'By day'),(T 'По месяцам' 'By month'),(T 'Все сессии' 'All sessions')))
    $period=History-Combo 25 290;$period.Top=165
    $sessions=New-Object HistorySessionList;$sessions.SetBounds(25,245,290,410);$sessions.BackColor=[Drawing.Color]::FromArgb(36,30,45);$sessions.ForeColor=[Drawing.Color]::White;$sessions.BorderStyle='None';$sessions.Font=New-Object Drawing.Font('Segoe UI',12);$sessions.ItemHeight=52;$sessions.IntegralHeight=$false;$sessions.DisplayMember='label';$window.Controls.Add($sessions)
    $prevSession=Dialog-Button $window '←' 1040 20 90 {if($sessions.SelectedIndex -gt 0){$sessions.SelectedIndex--}}
    $prevSession.Anchor='Top,Right'
    $nextSession=Dialog-Button $window '→' 1140 20 90 {if($sessions.SelectedIndex -lt $sessions.Items.Count-1){$sessions.SelectedIndex++}}
    $nextSession.Anchor='Top,Right';$sessions.Anchor='Top,Left,Right'
    $info=Dialog-Label $window '' 345 75 890 54 12;$info.Anchor='Top,Left,Right'
    $historyStats=New-Object SessionStats;$historyStats.SetBounds(345,140,890,145);$historyStats.Name='HistoryStats';$window.Controls.Add($historyStats)
    [void](Dialog-Label $window (T 'ЛУЧШИЙ СКОР · нажми, чтобы открыть' 'BEST SCORE · click to open') 345 305 890 25 11)
    $best=New-Object ScoreCards;$best.SetBounds(345,340,890,125);$best.Anchor='Top,Left,Right';$best.ApplyCardStyle($script:fontName,120,$false);$best.Add_ScoreClicked($openScoreHandler);$window.Controls.Add($best)
    $emptyBest=Dialog-Label $window (T 'Нет подходящих скоров для выбора лучшего.' 'No eligible scores for session best.') 365 375 840 40 13
    [void](Dialog-Label $window $(if($script:historyDirection -eq 'horizontal'){T 'ВСЕ СКОРЫ · слева направо' 'ALL SCORES · left to right'}else{T 'ВСЕ СКОРЫ · сверху вниз' 'ALL SCORES · top to bottom'}) 345 490 520 25 11)
    $sort=New-Object SettingsCombo;$sort.SetBounds(955,485,280,32);$sort.DropDownStyle='DropDownList';[void]$sort.Items.AddRange([object[]]@((T 'Сначала новые' 'Newest first'),(T 'Сначала лучшие pp' 'Highest pp first')));$sort.SelectedIndex=0;$sort.Anchor='Top,Right';$window.Controls.Add($sort)
    $scores=New-Object ScoreCards;$scores.SetBounds(345,530,890,175);$scores.Anchor='Top,Left,Right';$scores.ApplyCardStyle($script:fontName,135,$false);$scores.SetHorizontal(($script:historyDirection -eq 'horizontal'),600);$scores.Add_ScoreClicked($openScoreHandler);$window.Controls.Add($scores);if($script:historyDirection -eq 'vertical'){$scores.Height=175;$scores.ApplyCardStyle($script:fontName,110,$false)}
    $page=Dialog-Label $window '' 545 720 685 50 11
    [void](Dialog-Button $window $(if($script:historyDirection -eq 'vertical'){'↑'}else{'←'}) 345 715 85 {$scores.TopIndex=[math]::Max(0,$scores.TopIndex-1)})
    [void](Dialog-Button $window $(if($script:historyDirection -eq 'vertical'){'↓'}else{'→'}) 445 715 85 {$scores.TopIndex=[math]::Min([math]::Max(0,$scores.Items.Count-1),$scores.TopIndex+1)})
    [void](Dialog-Label $window (T 'Текущая сессия продолжает записываться.' 'Your current session keeps recording.') 25 675 290 70 10)
    $group.Name='HistoryGroup';$period.Name='HistoryPeriod';$sessions.Name='HistorySession';$scores.Name='HistoryScores';$best.Name='HistoryBest';$sort.Name='HistorySort'
    $selected=@{session=$null;index=@();updating=$false}
    $drawScores={
        $entries=New-Object 'System.Collections.Generic.List[ScoreEntry]'
        $ordered=if($sort.SelectedIndex -eq 1){@($selected.session.plays|Sort-Object pp -Descending)}else{@($selected.session.plays|Sort-Object time -Descending)}
        foreach($p in $ordered){$entries.Add((Make-ScoreEntry $p))}
        $scores.ReplaceCards($entries.ToArray());$scores.TopIndex=0
        $page.Text=if($script:historyDirection -eq 'vertical'){T "Скоров: $($entries.Count) · прокрутка сверху вниз ↑ ↓" "Scores: $($entries.Count) · scroll top / bottom ↑ ↓"}else{T "Скоров: $($entries.Count) · прокрутка слева направо ← →" "Scores: $($entries.Count) · scroll left / right ← →"}
    }
    $selectSession={
        if($selected.updating){return}
        $best.ClearCards();$scores.ClearCards();$best.Invalidate();$scores.Invalidate();$selected.session=$null;$emptyBest.Visible=$true;$recapHistory.Enabled=$false;$historyStats.SetValues('—',0,0,'00:00:00','0 pp',($script:language -eq 'en'),$true)
        $prevSession.Enabled=($sessions.SelectedIndex -gt 0);$nextSession.Enabled=($sessions.SelectedIndex -ge 0 -and $sessions.SelectedIndex -lt $sessions.Items.Count-1)
        if(!$sessions.SelectedItem){$info.Text=T 'Здесь пока пусто. Выбери другой период или сыграй первую сессию.' 'Nothing here yet. Choose another period or play your first session.';$historyStats.SetValues('—',0,0,'00:00:00','0 pp',($script:language -eq 'en'),$true);$page.Text='';$recapHistory.Enabled=$false;return}
        try{
            $s=[IO.File]::ReadAllText($sessions.SelectedItem.path)|ConvertFrom-Json
            if(!$s.started -or $null -eq $s.plays){throw 'Invalid session'}
            $selected.session=$s;$recapHistory.Enabled=$true;$plays=@($s.plays);$top=Get-SessionBest $plays
            $gain=if($null -ne $s.baseline -and $null -ne $s.latest){'{0:+0.00;-0.00;0.00}' -f ($s.latest-$s.baseline)}else{'—'}
            $fc=@($plays|Where-Object fc).Count;$sum=[math]::Round([double]($plays|Measure-Object pp -Sum).Sum,2)
            $end=if($s.ended){[datetime]$s.ended}else{Get-Date};$duration=$end-[datetime]$s.started
            $info.Text=([datetime]$s.started).ToString('dddd, dd MMMM yyyy · HH:mm',[Globalization.CultureInfo]::GetCultureInfo($(if($script:language -eq 'en'){'en-US'}else{'ru-RU'})))+'  /  '+(T 'Сессия ' 'Session ')+($sessions.SelectedIndex+1)+' / '+$sessions.Items.Count
            $historyStats.SetValues(($gain+' pp'),$fc,$plays.Count,('{0:00}:{1:00}:{2:00}' -f [math]::Floor($duration.TotalHours),$duration.Minutes,$duration.Seconds),($sum.ToString('0.00')+' pp'),($script:language -eq 'en'),[bool]$s.ended)
            if($top){$best.ReplaceCards([ScoreEntry[]]@((Make-ScoreEntry $top 'best')));$emptyBest.Visible=$false}
            & $drawScores
        }catch{$info.Text=T 'Не удалось прочитать сессию. Выбери другую.' 'Could not read this session. Choose another one.'}
    }
    $filterSessions={
        if($selected.updating){return}
        $selected.updating=$true;$sessions.Items.Clear()
        $mode=@('day','month','all')[[math]::Max(0,$group.SelectedIndex)];$key=if($period.SelectedIndex -ge 0){$period.Tag[$period.SelectedIndex].key}else{''}
        foreach($item in $selected.index){if($mode -eq 'all' -or $item.$mode -eq $key){[void]$sessions.Items.Add($item)}}
        if($sessions.Items.Count){$sessions.SelectedIndex=0}
        $selected.updating=$false;& $selectSession
    }
    $filterPeriods={
        $selected.updating=$true;$period.Items.Clear()
        $mode=@('day','month','all')[[math]::Max(0,$group.SelectedIndex)]
        $period.Tag=@(Get-HistoryPeriods $selected.index $mode);foreach($item in $period.Tag){[void]$period.Items.Add($item.label)}
        if($period.Items.Count){$period.SelectedIndex=0}
        $selected.updating=$false;& $filterSessions
    }
    $reload={if($script:session){Save-Session};$selected.index=@(Get-HistoryIndex);& $filterPeriods}
    $group.Add_SelectedIndexChanged($filterPeriods);$period.Add_SelectedIndexChanged($filterSessions);$sessions.Add_SelectedIndexChanged($selectSession);$sort.Add_SelectedIndexChanged({if($selected.session){& $drawScores}})
    [void](Dialog-Button $window (T 'Обновить архив' 'Refresh archive') 25 785 190 $reload)
    [void](Dialog-Button $window (T 'Экспорт сессии в CSV' 'Export session to CSV') 235 785 240 {
        if(!$selected.session){return};$save=New-Object Windows.Forms.SaveFileDialog;$save.Filter='CSV (*.csv)|*.csv';$save.FileName='osu-session.csv'
        if($save.ShowDialog() -eq 'OK'){$selected.session.plays|Export-Csv -LiteralPath $save.FileName -NoTypeInformation -Encoding UTF8};$save.Dispose()
    })
    $recapHistory=Dialog-Button $window (T 'Карточка итогов · PNG' 'Session card · PNG') 495 785 270 {if($selected.session){Show-SessionCard $selected.session}};$recapHistory.Name='HistoryRecap'
    $closeHistory=Dialog-Button $window (T 'Закрыть' 'Close') 1090 785 145 {$window.Close()};$closeHistory.Anchor='Bottom,Right'
    $group.SelectedIndex=0;& $reload
    [void]$window.ShowDialog($form);$window.Dispose()
}

function New-SessionRecap($session,$name,$background,$dim=65){
    $card=New-Object SessionRecap;$card.English=($script:language -eq 'en');$card.Player=$name;$card.Dim=$dim
    $card.Client=if($session.client){[string]$session.client}else{'stable'}
    $card.DateText=([datetime]$session.started).ToString('dd MMMM yyyy · HH:mm',[Globalization.CultureInfo]::GetCultureInfo($(if($script:language -eq 'en'){'en-US'}else{'ru-RU'})))+'  ·  '+$(if($session.ended){T 'Сессия завершена' 'Session complete'}else{T 'Текущие итоги' 'Session so far'})
    $plays=@($session.plays);$card.FcCount=@($plays|Where-Object fc).Count;$card.PlayCount=$plays.Count
    $card.Gain=if($null -ne $session.baseline -and $null -ne $session.latest){'{0:+0.00;-0.00;0.00}' -f ($session.latest-$session.baseline)}else{'—'}
    $end=if($session.ended){[datetime]$session.ended}else{Get-Date};$duration=$end-[datetime]$session.started
    $card.Duration='{0:00}:{1:00}:{2:00}' -f [math]::Max(0,[math]::Floor($duration.TotalHours)),[math]::Max(0,$duration.Minutes),[math]::Max(0,$duration.Seconds)
    $card.Total=('{0:0.00} pp' -f [double]($plays|Measure-Object pp -Sum).Sum)
    $top=Get-SessionBest $plays
    if($top){$card.SetBest((Make-ScoreEntry $top 'best'))}else{$card.SetBest($null)}
    $card.SetWallpaper($background);return $card
}
function Show-SessionCard($session){
    if(!$session){return}
    # Snapshot the selected session: live tracking can continue without changing the preview.
    $snapshot=$session|ConvertTo-Json -Depth 12|ConvertFrom-Json
    $dialog=Dialog-Form (T 'Карточка итогов сессии' 'Session recap card') 1100 840;$dialog.FormBorderStyle='FixedDialog';$dialog.MaximizeBox=$false
    [void](Dialog-Label $dialog (T 'Карточка, которой хочется поделиться' 'A session worth sharing') 25 15 1000 40 21)
    [void](Dialog-Label $dialog (T 'Ник на карточке' 'Name on card') 25 70 210 23 10)
    $name=New-Object Windows.Forms.TextBox;$name.SetBounds(25,98,240,30);$name.MaxLength=60;$name.Text=if($snapshot.playerName){[string]$snapshot.playerName}else{'osu! player'};$dialog.Controls.Add($name);$name.Name='RecapName'
    [void](Dialog-Label $dialog (T 'Фон карточки' 'Card background') 285 70 280 23 10)
    $background=New-Object SettingsCombo;$background.SetBounds(285,98,300,32);[void]$background.Items.AddRange([object[]]@((T 'Фон программы' 'App wallpaper'),(T 'Фон лучшей карты' 'Best map background'),(T 'Моё изображение…' 'Custom image…'),(T 'Без изображения' 'No image')));$background.SelectedIndex=0;$background.Name='RecapBackground';$dialog.Controls.Add($background)
    [void](Dialog-Label $dialog (T 'Затемнение, %' 'Dimming, %') 610 70 160 23 10)
    $dim=New-Object SettingsNumber;$dim.SetBounds(610,98,150,32);$dim.Minimum=10;$dim.Maximum=90;$dim.Value=65;$dim.Increment=5;$dim.Name='RecapDim';$dialog.Controls.Add($dim)
    $picture=New-Object Windows.Forms.PictureBox;$picture.SetBounds(125,155,850,612);$picture.SizeMode='Zoom';$picture.Name='RecapPreview';$dialog.Controls.Add($picture)
    $draft=@{card=$null;custom='';changing=$false}
    $top=Get-SessionBest @($snapshot.plays)
    $update={
        if($draft.changing){return}
        $path=switch($background.SelectedIndex){0{Get-MenuBackgroundPath $script:backgroundId $script:customBackgroundPath}1{if($top){$top.background}}2{$draft.custom}default{$null}}
        $next=New-SessionRecap $snapshot $name.Text $path ([int]$dim.Value)
        try{$next.CreateControl();$image=$next.RenderImage();$old=$picture.Image;$picture.Image=$image;if($old){$old.Dispose()};$old=$draft.card;$draft.card=$next;if($old){$old.Dispose()}}catch{$next.Dispose();throw}
    }
    $background.Add_SelectedIndexChanged({
        if($background.SelectedIndex -eq 2 -and !$draft.changing){$open=New-Object Windows.Forms.OpenFileDialog;$open.Filter='Images|*.png;*.jpg;*.jpeg;*.bmp';try{if($open.ShowDialog() -eq 'OK'){if((Get-Item -LiteralPath $open.FileName).Length -gt 26214400){throw (T 'Файл должен быть меньше 25 МБ' 'Image must be smaller than 25 MB')};$check=[Drawing.Image]::FromFile($open.FileName);try{if($check.Width -gt 16000 -or $check.Height -gt 16000){throw 'Image is too large'}}finally{$check.Dispose()};$draft.custom=$open.FileName}else{$draft.changing=$true;$background.SelectedIndex=0;$draft.changing=$false}}catch{[void][Windows.Forms.MessageBox]::Show($_.Exception.Message);$draft.changing=$true;$background.SelectedIndex=0;$draft.changing=$false}finally{$open.Dispose()}}
        & $update
    })
    $name.Add_TextChanged($update);$dim.Add_ValueChanged($update)
    $save=Dialog-Button $dialog (T 'Сохранить PNG' 'Save PNG') 770 785 185 {
        $file=New-Object Windows.Forms.SaveFileDialog;$file.Filter='PNG (*.png)|*.png';$file.FileName='osu-session-'+([datetime]$snapshot.started).ToString('yyyy-MM-dd-HHmm')+'.png'
        try{if($file.ShowDialog() -eq 'OK'){$picture.Image.Save($file.FileName,[Drawing.Imaging.ImageFormat]::Png);$message.Text=T 'Карточка сохранена!' 'Card saved!'}}catch{[void][Windows.Forms.MessageBox]::Show($_.Exception.Message)}finally{$file.Dispose()}
    };$save.Primary=$true
    [void](Dialog-Button $dialog (T 'Закрыть' 'Close') 970 785 110 {$dialog.Close()})
    $message=Dialog-Label $dialog (T 'PNG · 1000 × 720 · предпросмотр совпадает с экспортом' 'PNG · 1000 × 720 · preview matches export') 25 790 720 35 10
    & $update
    try{[void]$dialog.ShowDialog($form)}finally{if($draft.card){$draft.card.Dispose()};if($picture.Image){$picture.Image.Dispose();$picture.Image=$null};$dialog.Dispose()}
}
