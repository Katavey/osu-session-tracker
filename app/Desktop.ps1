$script:appRoot=$PSScriptRoot
$script:fontName='Comic Sans MS';$script:fontChosen=$false
$script:theme='rose';$script:backgroundId='cafe';$script:customBackgroundPath=''
$script:backgroundDim=67;$script:mascotEnabled=$true;$script:animationsEnabled=$true
$script:compactCards=$false;$script:overlayEnabled=$false;$script:overlayServer=$null
$script:overlayRecentEnabled=$true;$script:overlayRecentCount=3;$script:overlayBestEnabled=$true
$script:overlayFontName='';$script:overlayAnimation='slide';$script:overlayCardSize='normal';$script:overlayWidth=720;$script:overlayOpacity=89;$script:overlayShowStats=$true
$script:lastOverlayUpdate=[datetime]::MinValue
$installedFonts=New-Object Drawing.Text.InstalledFontCollection
$script:fontChoices=@('Comic Sans MS','Segoe UI','Calibri','Arial','Trebuchet MS','Verdana','Tahoma','Georgia','Consolas','Times New Roman' | Where-Object {$installedFonts.Families.Name -contains $_})
$installedFonts.Dispose()
if([IO.File]::Exists($script:settingsPath)){
    try{$prefs=[IO.File]::ReadAllText($script:settingsPath)|ConvertFrom-Json
        foreach($name in @('fontName','fontChosen','theme','backgroundId','customBackgroundPath','backgroundDim','mascotEnabled','animationsEnabled','compactCards','overlayEnabled','overlayRecentEnabled','overlayRecentCount','overlayBestEnabled','overlayFontName','overlayAnimation','overlayCardSize','overlayWidth','overlayOpacity','overlayShowStats')){
            if($null -ne $prefs.$name){Set-Variable -Scope Script -Name $name -Value $prefs.$name}
        }
    }catch{}
}
if($script:fontChoices -notcontains $script:fontName){$script:fontName=$script:fontChoices[0]}
if($script:theme -notin @('rose','ocean','lavender')){$script:theme='rose'}
if($script:backgroundId -notin @('cafe','lake','room','none','custom')){$script:backgroundId='cafe'}
$script:backgroundDim=[math]::Max(0,[math]::Min(90,[int]$script:backgroundDim))
$script:overlayRecentCount=[math]::Max(0,[math]::Min(5,[int]$script:overlayRecentCount))
if(!$script:overlayRecentEnabled){$script:overlayRecentCount=0}
if($script:overlayAnimation -notin @('none','slide','fade','pop')){$script:overlayAnimation='slide'}
if($script:overlayCardSize -notin @('compact','normal','large')){$script:overlayCardSize='normal'}
if($script:overlayFontName -and $script:fontChoices -notcontains $script:overlayFontName){$script:overlayFontName=''}
$script:overlayWidth=[math]::Max(600,[math]::Min(1200,[int]$script:overlayWidth))
$script:overlayOpacity=[math]::Max(0,[math]::Min(100,[int]$script:overlayOpacity))
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
    $accent=switch($script:theme){'ocean'{[Drawing.Color]::FromArgb(87,192,218)}'lavender'{[Drawing.Color]::FromArgb(178,146,235)}default{[Drawing.Color]::FromArgb(239,105,164)}}
    [SessionTheme]::Accent=$accent
    [SessionTheme]::PanelColor=switch($script:theme){'ocean'{[Drawing.Color]::FromArgb(26,40,52)}'lavender'{[Drawing.Color]::FromArgb(38,32,56)}default{[Drawing.Color]::FromArgb(38,31,46)}}
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
    $best=$plays|Sort-Object pp -Descending|Select-Object -First 1
    $gain=$null;if($s -and $null -ne $s.baseline -and $null -ne $s.latest){$gain=[math]::Round($s.latest-$s.baseline,2)}
    $seconds=0;if($s){$end=if($s.ended){[datetime]$s.ended}else{Get-Date};$seconds=[math]::Max(0,[int]($end-[datetime]$s.started).TotalSeconds)}
    $recent=@()
    if($script:overlayRecentEnabled){for($i=$plays.Count-1;$i -ge 0 -and $recent.Count -lt $script:overlayRecentCount;$i--){$recent+=Convert-OverlayScore $plays[$i]}}
    return @{animation=$script:overlayAnimation;cardSize=$script:overlayCardSize;width=$script:overlayWidth;opacity=$script:overlayOpacity;showStats=$script:overlayShowStats;showRecent=($script:overlayRecentCount -gt 0);showBest=$script:overlayBestEnabled;recent=@($recent);best=$(if($script:overlayBestEnabled){Convert-OverlayScore $best}else{$null});animate=($script:overlayAnimation -ne 'none');language=$script:language;font=$(if($script:overlayFontName){$script:overlayFontName}else{$script:fontName});accent=('#{0:X2}{1:X2}{2:X2}' -f [SessionTheme]::Accent.R,[SessionTheme]::Accent.G,[SessionTheme]::Accent.B);gain=$gain;fc=@($plays|Where-Object fc).Count;plays=$plays.Count;bestPp=$(if($best){$best.pp}else{$null});bestMap=$(if($best){$best.map}else{''});seconds=$seconds;ended=[bool]($s -and $s.ended)}
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
    $dialog=Dialog-Form (T 'Настройки и предпросмотр · 2.1' 'Settings & preview · 2.1') 1240 880
    $dialog.FormBorderStyle='FixedDialog';$dialog.MaximizeBox=$false
    $tabs=New-Object SettingsTabs;$tabs.SetBounds(20,100,1200,680);$tabs.Anchor='Top,Bottom,Left,Right';$dialog.Controls.Add($tabs)
    $appearance=New-Object Windows.Forms.TabPage;$appearance.Text=T 'Оформление' 'Appearance';$appearance.BackColor=[Drawing.Color]::FromArgb(23,20,29);$tabs.TabPages.Add($appearance)
    $obs=New-Object Windows.Forms.TabPage;$obs.Text='OBS';$obs.BackColor=$appearance.BackColor;$tabs.TabPages.Add($obs)
    $draft=@{backgroundId=$script:backgroundId;customPath=$script:customBackgroundPath;previewServer=$null;previewToken=''}
    function Settings-Combo($parent,$label,$y,$values,$selected=0){
        [void](Dialog-Label $parent $label 20 $y 550 25 10)
        $c=New-Object SettingsCombo;$c.SetBounds(20,($y+28),550,32);$c.DropDownStyle='DropDownList';[void]$c.Items.AddRange([object[]]$values);$c.SelectedIndex=$selected;$parent.Controls.Add($c);return $c
    }
    function Settings-Check($parent,$text,$y,$value){$c=New-Object SettingsToggle;$c.Text=$text;$c.SetBounds(20,$y,550,28);$c.Checked=$value;$parent.Controls.Add($c);return $c}
    function Settings-Number($parent,$text,$y,$min,$max,$value,$step=1){[void](Dialog-Label $parent $text 20 $y 420 28 10);$n=New-Object SettingsNumber;$n.SetBounds(455,$y,115,30);$n.Minimum=$min;$n.Maximum=$max;$n.Increment=$step;$n.Value=$value;$parent.Controls.Add($n);return $n}
    $font=Settings-Combo $appearance (T 'Шрифт программы' 'App font') 15 $script:fontChoices ($script:fontChoices.IndexOf($script:fontName))
    $themes=Settings-Combo $appearance (T 'Тема' 'Theme') 90 @((T 'Розовая' 'Rose'),(T 'Океан' 'Ocean'),(T 'Лаванда' 'Lavender')) (@('rose','ocean','lavender').IndexOf($script:theme))
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
    [void](Dialog-Label $appearance (T 'Предпросмотр справа. Изменения сохранятся после «Применить».' 'Preview on the right. Changes are saved when you click Apply.') 20 555 550 70 10)
    $appPreview=New-Object SettingsPreview;$appPreview.SetBounds(600,50,565,560);$appPreview.Anchor='Top,Left';$appPreview.SetMascot((Join-Path $script:appRoot 'assets/mascot.png'));$appearance.Controls.Add($appPreview)
    $obsCheck=Settings-Check $obs (T 'Включить оверлей OBS' 'Enable OBS overlay') 15 $script:overlayEnabled
    $statsCheck=Settings-Check $obs (T 'Показывать счётчики сессии' 'Show session statistics') 50 $script:overlayShowStats
    $bestCheck=Settings-Check $obs (T 'Показывать лучший скор сессии' 'Show session best score') 85 $script:overlayBestEnabled
    $recentCount=Settings-Number $obs (T 'Последние скоры · 0 = скрыть' 'Recent scores · 0 = hide') 125 0 5 $script:overlayRecentCount
    $obsFonts=@((T 'Как в программе' 'Same as the app'))+@($script:fontChoices)
    $obsFontIndex=if($script:overlayFontName){1+$script:fontChoices.IndexOf($script:overlayFontName)}else{0}
    $obsFont=Settings-Combo $obs (T 'Шрифт OBS · независимо от программы' 'OBS font · independent from app') 170 $obsFonts $obsFontIndex
    $obsAnimation=Settings-Combo $obs (T 'Анимация новых карточек' 'New card animation') 245 @((T 'Нет' 'None'),(T 'Сдвиг' 'Slide'),(T 'Появление' 'Fade'),(T 'Увеличение' 'Pop')) (@('none','slide','fade','pop').IndexOf($script:overlayAnimation))
    $obsSize=Settings-Combo $obs (T 'Размер карточек' 'Card size') 320 @((T 'Компактный · 90 px' 'Compact · 90 px'),(T 'Обычный · 110 px' 'Normal · 110 px'),(T 'Крупный · 145 px' 'Large · 145 px')) (@('compact','normal','large').IndexOf($script:overlayCardSize))
    $obsWidth=Settings-Number $obs (T 'Ширина панели, px' 'Panel width, px') 400 600 1200 $script:overlayWidth 20
    $obsOpacity=Settings-Number $obs (T 'Непрозрачность фона, %' 'Panel background opacity, %') 445 0 100 $script:overlayOpacity 5
    [void](Dialog-Button $obs (T 'Точный предпросмотр в браузере' 'Exact browser preview') 20 495 550 {
        try{if(!$draft.previewServer){$draft.previewServer=New-Object ObsOverlay;$draft.previewServer.StartPreview((Join-Path $script:appRoot 'assets/overlay.html'))};& $syncPreview $true;Start-Process $draft.previewServer.Url}catch{[void][Windows.Forms.MessageBox]::Show($_.Exception.Message)}
    })
    [void](Dialog-Button $obs (T 'Повторить анимацию' 'Replay animation') 20 545 550 {$obsPreview.Replay();if($draft.previewServer){& $syncPreview $true}})
    $obsInfo=Dialog-Label $obs '' 20 595 550 50 10
    $obsPreview=New-Object SettingsPreview;$obsPreview.ObsMode=$true;$obsPreview.SetBounds(600,50,565,560);$obsPreview.Anchor='Top,Left';$obs.Controls.Add($obsPreview)
    $previewLabel=Dialog-Label $obs (T 'Демо · для точных анимаций открой браузерный предпросмотр' 'Demo · open the browser preview for exact animations') 600 620 565 25 9
    $font.Name='AppFont';$themes.Name='AppTheme';$gallery.Name='AppWallpaper';$dim.Name='AppDim';$mascotCheck.Name='ShowMascot';$voiceCheck.Name='Voice';$animationCheck.Name='AppAnimation';$compactCheck.Name='CompactCards'
    $tabs.Name='SettingsTabs';$recentCount.Name='ObsRecentCount';$obsFont.Name='ObsFont';$obsAnimation.Name='ObsAnimation';$obsSize.Name='ObsSize';$obsWidth.Name='ObsWidth';$obsOpacity.Name='ObsOpacity';$bestCheck.Name='ObsBest';$statsCheck.Name='ObsStats';$obsCheck.Name='ObsEnabled';$appPreview.Name='AppearancePreview';$obsPreview.Name='ObsPreview'
    $updateAppearance={
        $draft.backgroundId=@('cafe','lake','room','none','custom')[$gallery.SelectedIndex]
        $appPreview.PreviewFont=[string]$font.SelectedItem;$appPreview.Dim=[int]$dim.Value;$appPreview.ShowMascot=$mascotCheck.Checked;$appPreview.Compact=$compactCheck.Checked
        $appPreview.AccentColor=switch($themes.SelectedIndex){1{[Drawing.Color]::FromArgb(87,192,218)}2{[Drawing.Color]::FromArgb(178,146,235)}default{[Drawing.Color]::FromArgb(239,105,164)}}
        $appPreview.SetWallpaper((Get-MenuBackgroundPath $draft.backgroundId $draft.customPath));$appPreview.Invalidate();if($animationCheck.Checked){$appPreview.Replay()}else{$appPreview.StopPreview()}
        if($obsPreview){& $updateObs}
    }
    $syncPreview={param($replay=$false)
        if(!$draft.previewServer){return}
        $recent=@();for($i=0;$i -lt [int]$recentCount.Value;$i++){$recent+=New-DemoScore $draft.previewServer $i}
        $demoBest=New-DemoScore $draft.previewServer 8
        $state=@{preview=$true;previewToken=$(if($replay){[guid]::NewGuid().ToString()}else{$draft.previewToken});language=$script:language;font=$(if($obsFont.SelectedIndex -gt 0){[string]$obsFont.SelectedItem}else{[string]$font.SelectedItem});accent=('#{0:X2}{1:X2}{2:X2}' -f $appPreview.AccentColor.R,$appPreview.AccentColor.G,$appPreview.AccentColor.B);gain=23.35;fc=3;plays=8;bestPp=$demoBest.pp;best=$demoBest;recent=@($recent);seconds=2525;ended=$false;animate=$true;animation=@('none','slide','fade','pop')[$obsAnimation.SelectedIndex];cardSize=@('compact','normal','large')[$obsSize.SelectedIndex];width=[int]$obsWidth.Value;opacity=[int]$obsOpacity.Value;showStats=$statsCheck.Checked;showBest=$bestCheck.Checked;showRecent=($recentCount.Value -gt 0)}
        $draft.previewToken=$state.previewToken;$draft.previewServer.SetState(($state|ConvertTo-Json -Depth 7 -Compress))
    }
    $updateObs={
        $obsPreview.PreviewFont=if($obsFont.SelectedIndex -gt 0){[string]$obsFont.SelectedItem}else{[string]$font.SelectedItem}
        $obsPreview.AccentColor=$appPreview.AccentColor;$obsPreview.RecentCount=[int]$recentCount.Value;$obsPreview.ShowBest=$bestCheck.Checked;$obsPreview.ShowStats=$statsCheck.Checked
        $obsPreview.CardHeight=@(90,110,145)[$obsSize.SelectedIndex];$obsPreview.OverlayWidth=[int]$obsWidth.Value;$obsPreview.PanelOpacity=[int]$obsOpacity.Value;$obsPreview.Animation=@('none','slide','fade','pop')[$obsAnimation.SelectedIndex]
        $obsPreview.SetWallpaper((Join-Path $script:appRoot 'assets/gallery-lake.png'));$obsPreview.Invalidate();$obsPreview.Replay()
        $canvas=Get-ObsCanvasSize $obsWidth.Value (@('compact','normal','large')[$obsSize.SelectedIndex]) $recentCount.Value $bestCheck.Checked $statsCheck.Checked
        $obsInfo.Text=(T 'Размер источника OBS: ' 'OBS source size: ')+"$($canvas.width) × $($canvas.height)"+"`r`n"+(T 'Предпросмотр не меняет виджет на стриме.' 'Preview does not change your live overlay.')
        & $syncPreview
    }
    foreach($c in @($font,$themes,$gallery)){$c.Add_SelectedIndexChanged($updateAppearance)}
    $dim.Add_ValueChanged($updateAppearance);foreach($c in @($mascotCheck,$compactCheck,$animationCheck)){$c.Add_CheckedChanged($updateAppearance)}
    foreach($c in @($obsFont,$obsAnimation,$obsSize)){$c.Add_SelectedIndexChanged($updateObs)}
    foreach($c in @($obsWidth,$obsOpacity,$recentCount)){$c.Add_ValueChanged($updateObs)}
    foreach($c in @($statsCheck,$bestCheck)){$c.Add_CheckedChanged($updateObs)}
    $apply={
        $script:fontName=[string]$font.SelectedItem;$script:fontChosen=$true;$script:theme=@('rose','ocean','lavender')[$themes.SelectedIndex]
        $script:backgroundId=$draft.backgroundId;$script:customBackgroundPath=$draft.customPath;$script:backgroundDim=[int]$dim.Value
        $script:mascotEnabled=$mascotCheck.Checked;$script:voiceEnabled=$voiceCheck.Checked;$script:animationsEnabled=$animationCheck.Checked;$script:compactCards=$compactCheck.Checked
        $script:overlayEnabled=$obsCheck.Checked;$script:overlayShowStats=$statsCheck.Checked;$script:overlayBestEnabled=$bestCheck.Checked;$script:overlayRecentCount=[int]$recentCount.Value;$script:overlayRecentEnabled=($recentCount.Value -gt 0)
        $script:overlayFontName=if($obsFont.SelectedIndex -gt 0){[string]$obsFont.SelectedItem}else{''};$script:overlayAnimation=@('none','slide','fade','pop')[$obsAnimation.SelectedIndex]
        $script:overlayCardSize=@('compact','normal','large')[$obsSize.SelectedIndex];$script:overlayWidth=[int]$obsWidth.Value;$script:overlayOpacity=[int]$obsOpacity.Value
        if(!$script:voiceEnabled){[MascotAudio]::Stop()};Apply-DesktopStyle;Apply-Language
        try{Sync-Overlay}catch{$script:overlayEnabled=$false;$obsCheck.Checked=$false;[void][Windows.Forms.MessageBox]::Show($_.Exception.Message)}
        Save-Settings
        $saveInfo.Text=T 'Сохранено. Настройки OBS применены.' 'Saved. OBS settings applied.'
    }
    [void](Dialog-Button $dialog (T 'Скопировать URL OBS' 'Copy OBS URL') 20 805 270 {if($script:overlayServer){[Windows.Forms.Clipboard]::SetText($script:overlayServer.Url);$saveInfo.Text=$script:overlayServer.Url}else{$saveInfo.Text=T 'Сначала включи OBS и нажми «Применить».' 'Enable OBS and click Apply first.'}})
    $saveInfo=Dialog-Label $dialog '' 315 795 540 70 10
    $applyButton=Dialog-Button $dialog (T 'Применить' 'Apply') 875 805 160 $apply;$applyButton.Primary=$true
    [void](Dialog-Button $dialog (T 'Закрыть' 'Close') 1055 805 165 {$dialog.Close()})
    [void](Dialog-Label $dialog (T 'Настрой под себя' 'Make it yours') 25 15 760 35 21)
    $subtitle=Dialog-Label $dialog (T 'Оформление, OBS и живой предпросмотр — в одном месте.' 'Appearance, OBS and live previews — all in one place.') 25 55 760 30 10
    $subtitle.ForeColor=[Drawing.Color]::FromArgb(171,157,185)
    $appearanceNav=Dialog-Button $dialog (T 'Оформление' 'Appearance') 875 28 160 {$tabs.SelectedIndex=0}
    $obsNav=Dialog-Button $dialog 'OBS' 1055 28 165 {$tabs.SelectedIndex=1}
    $appearanceNav.Primary=$true
    $tabs.Add_SelectedIndexChanged({$appearanceNav.Primary=($tabs.SelectedIndex -eq 0);$obsNav.Primary=($tabs.SelectedIndex -eq 1);$appearanceNav.Invalidate();$obsNav.Invalidate()})
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
    Settings-Section $obs 0 165;Settings-Section $obs 165 225;Settings-Section $obs 395 90;Settings-Section $obs 490 165
    function Settings-Typography($parent){foreach($child in $parent.Controls){$oldFont=$child.Font;$child.Font=New-Object Drawing.Font('Segoe UI',$oldFont.Size,$oldFont.Style);Settings-Typography $child}}
    $dialog.Font=New-Object Drawing.Font('Segoe UI',11);Settings-Typography $dialog
    & $updateAppearance
    try{[void]$dialog.ShowDialog($form)}finally{if($draft.previewServer){$draft.previewServer.Dispose()};[MascotAudio]::Stop();$dialog.Dispose()}
}
function Get-HistoryIndex {
    $items=New-Object 'System.Collections.Generic.List[object]'
    if(![IO.Directory]::Exists($dataDir)){return @()}
    foreach($file in Get-ChildItem -LiteralPath $dataDir -Filter '*.json'){
        $date=$file.LastWriteTime
        try{
            $reader=[IO.File]::OpenText($file.FullName)
            try{for($lineIndex=0;$lineIndex -lt 16 -and !$reader.EndOfStream;$lineIndex++){$line=$reader.ReadLine();if($line -match '"started"\s*:\s*"([^"]+)"'){$date=[datetime]$Matches[1];break}}}finally{$reader.Dispose()}
        }catch{}
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
    $window=Dialog-Form (T 'Архив сессий · 2.1' 'Session archive · 2.1') 1280 760
    $window.MinimumSize=New-Object Drawing.Size(1050,800)
    [void](Dialog-Label $window (T 'АРХИВ СЕССИЙ' 'SESSION ARCHIVE') 25 15 600 34 20)
    [void](Dialog-Label $window (T 'Группировать' 'Group by') 25 60 175 25 10)
    [void](Dialog-Label $window (T 'Период' 'Period') 220 60 260 25 10)
    [void](Dialog-Label $window (T 'Сессия · листай стрелками ← →' 'Session · browse with ← →') 510 60 540 25 10)
    function History-Combo($x,$width){$c=New-Object Windows.Forms.ComboBox;$c.SetBounds($x,90,$width,32);$c.DropDownStyle='DropDownList';$window.Controls.Add($c);return $c}
    $group=History-Combo 25 175;[void]$group.Items.AddRange([object[]]@((T 'По дням' 'By day'),(T 'По месяцам' 'By month'),(T 'Все сессии' 'All sessions')))
    $period=History-Combo 220 265;$period.DisplayMember='label'
    $sessions=History-Combo 510 530;$sessions.DisplayMember='label'
    $prevSession=Dialog-Button $window '←' 1060 85 85 {if($sessions.SelectedIndex -gt 0){$sessions.SelectedIndex--}}
    $prevSession.Anchor='Top,Right'
    $nextSession=Dialog-Button $window '→' 1160 85 85 {if($sessions.SelectedIndex -lt $sessions.Items.Count-1){$sessions.SelectedIndex++}}
    $nextSession.Anchor='Top,Right';$sessions.Anchor='Top,Left,Right'
    $info=Dialog-Label $window '' 25 140 1220 65 12;$info.Anchor='Top,Left,Right'
    [void](Dialog-Label $window (T 'ЛУЧШИЙ СКОР · нажми, чтобы открыть' 'BEST SCORE · click to open') 25 215 1100 25 11)
    $best=New-Object ScoreCards;$best.SetBounds(25,247,1220,125);$best.Anchor='Top,Left,Right';$best.ApplyCardStyle($script:fontName,120,$false);$best.Add_ScoreClicked($openScoreHandler);$window.Controls.Add($best)
    $emptyBest=Dialog-Label $window (T 'В этой сессии пока нет скоров.' 'No scores in this session yet.') 45 280 1000 40 13
    [void](Dialog-Label $window (T 'ВСЕ СКОРЫ · горизонтальная лента' 'ALL SCORES · horizontal gallery') 25 390 800 25 11)
    $sort=New-Object Windows.Forms.ComboBox;$sort.SetBounds(955,385,290,32);$sort.DropDownStyle='DropDownList';[void]$sort.Items.AddRange([object[]]@((T 'Сначала новые' 'Newest first'),(T 'Сначала лучшие pp' 'Highest pp first')));$sort.SelectedIndex=0;$sort.Anchor='Top,Right';$window.Controls.Add($sort)
    $scores=New-Object ScoreCards;$scores.SetBounds(25,430,1220,175);$scores.Anchor='Top,Left,Right';$scores.ApplyCardStyle($script:fontName,135,$false);$scores.SetHorizontal($true,600);$scores.Add_ScoreClicked($openScoreHandler);$window.Controls.Add($scores)
    $page=Dialog-Label $window '' 235 620 780 35 11
    [void](Dialog-Button $window '←' 25 615 85 {$scores.TopIndex=[math]::Max(0,$scores.TopIndex-1)})
    [void](Dialog-Button $window '→' 125 615 85 {$scores.TopIndex=[math]::Min([math]::Max(0,$scores.Items.Count-1),$scores.TopIndex+1)})
    $group.Name='HistoryGroup';$period.Name='HistoryPeriod';$sessions.Name='HistorySession';$scores.Name='HistoryScores';$best.Name='HistoryBest';$sort.Name='HistorySort'
    $selected=@{session=$null;index=@();updating=$false}
    $drawScores={
        $entries=New-Object 'System.Collections.Generic.List[ScoreEntry]'
        $ordered=if($sort.SelectedIndex -eq 1){@($selected.session.plays|Sort-Object pp -Descending)}else{@($selected.session.plays|Sort-Object time -Descending)}
        foreach($p in $ordered){$entries.Add((Make-ScoreEntry $p))}
        $scores.ReplaceCards($entries.ToArray());$scores.TopIndex=0
        $page.Text=T "Скоров: $($entries.Count) · колесо мыши и стрелки листают слева направо" "Scores: $($entries.Count) · scroll wheel and arrows move left / right"
    }
    $selectSession={
        if($selected.updating){return}
        $best.ClearCards();$scores.ClearCards();$best.Invalidate();$scores.Invalidate();$selected.session=$null;$emptyBest.Visible=$true
        $prevSession.Enabled=($sessions.SelectedIndex -gt 0);$nextSession.Enabled=($sessions.SelectedIndex -ge 0 -and $sessions.SelectedIndex -lt $sessions.Items.Count-1)
        if(!$sessions.SelectedItem){$info.Text=T 'В этом периоде нет сохранённых сессий.' 'No saved sessions in this period.';$page.Text='';return}
        try{
            $s=[IO.File]::ReadAllText($sessions.SelectedItem.path)|ConvertFrom-Json
            if(!$s.started -or $null -eq $s.plays){throw 'Invalid session'}
            $selected.session=$s;$plays=@($s.plays);$top=$plays|Sort-Object pp -Descending|Select-Object -First 1
            $gain=if($null -ne $s.baseline -and $null -ne $s.latest){'{0:+0.00;-0.00;0.00}' -f ($s.latest-$s.baseline)}else{'—'}
            $fc=@($plays|Where-Object fc).Count;$sum=[math]::Round([double]($plays|Measure-Object pp -Sum).Sum,2)
            $info.Text=([datetime]$s.started).ToString('dd.MM.yyyy HH:mm')+'  ·  '+(T 'Текущая сессия продолжает записываться' 'Your current session keeps recording')+"`r`n"+(T "Скоров: $($plays.Count)     FC: $fc     Профиль: $gain pp     Сумма карт: $sum pp" "Plays: $($plays.Count)     FCs: $fc     Profile: $gain pp     Total play pp: $sum pp")
            if($top){$best.ReplaceCards([ScoreEntry[]]@((Make-ScoreEntry $top 'best')));$emptyBest.Visible=$false}
            & $drawScores
        }catch{$info.Text=T 'Не удалось прочитать сессию. Выбери другую.' 'Could not read this session. Choose another one.'}
    }
    $filterSessions={
        if($selected.updating){return}
        $selected.updating=$true;$sessions.Items.Clear()
        $mode=@('day','month','all')[[math]::Max(0,$group.SelectedIndex)];$key=if($period.SelectedItem){$period.SelectedItem.key}else{''}
        foreach($item in $selected.index){if($mode -eq 'all' -or $item.$mode -eq $key){[void]$sessions.Items.Add($item)}}
        if($sessions.Items.Count){$sessions.SelectedIndex=0}
        $selected.updating=$false;& $selectSession
    }
    $filterPeriods={
        $selected.updating=$true;$period.Items.Clear()
        $mode=@('day','month','all')[[math]::Max(0,$group.SelectedIndex)]
        foreach($item in @(Get-HistoryPeriods $selected.index $mode)){[void]$period.Items.Add($item)}
        if($period.Items.Count){$period.SelectedIndex=0}
        $selected.updating=$false;& $filterSessions
    }
    $reload={if($script:session){Save-Session};$selected.index=@(Get-HistoryIndex);& $filterPeriods}
    $group.Add_SelectedIndexChanged($filterPeriods);$period.Add_SelectedIndexChanged($filterSessions);$sessions.Add_SelectedIndexChanged($selectSession);$sort.Add_SelectedIndexChanged({if($selected.session){& $drawScores}})
    [void](Dialog-Button $window (T 'Обновить архив' 'Refresh archive') 25 690 240 $reload)
    [void](Dialog-Button $window (T 'Экспорт сессии в CSV' 'Export session to CSV') 285 690 295 {
        if(!$selected.session){return};$save=New-Object Windows.Forms.SaveFileDialog;$save.Filter='CSV (*.csv)|*.csv';$save.FileName='osu-session.csv'
        if($save.ShowDialog() -eq 'OK'){$selected.session.plays|Export-Csv -LiteralPath $save.FileName -NoTypeInformation -Encoding UTF8};$save.Dispose()
    })
    $closeHistory=Dialog-Button $window (T 'Закрыть' 'Close') 1090 690 155 {$window.Close()};$closeHistory.Anchor='Bottom,Right'
    $group.SelectedIndex=0;& $reload
    [void]$window.ShowDialog($form);$window.Dispose()
}
