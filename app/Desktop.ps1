$script:appRoot=$PSScriptRoot
$script:fontName='Comic Sans MS';$script:fontChosen=$false
$script:theme='rose';$script:backgroundId='cafe';$script:customBackgroundPath=''
$script:backgroundDim=67;$script:mascotEnabled=$true;$script:animationsEnabled=$true
$script:compactCards=$false;$script:overlayEnabled=$false;$script:overlayServer=$null
$script:overlayRecentEnabled=$true;$script:overlayRecentCount=3;$script:overlayBestEnabled=$true
$script:lastOverlayUpdate=[datetime]::MinValue
$installedFonts=New-Object Drawing.Text.InstalledFontCollection
$script:fontChoices=@('Comic Sans MS','Segoe UI','Calibri','Arial','Trebuchet MS','Verdana','Tahoma','Georgia','Consolas','Times New Roman' | Where-Object {$installedFonts.Families.Name -contains $_})
$installedFonts.Dispose()
if([IO.File]::Exists($script:settingsPath)){
    try{$prefs=[IO.File]::ReadAllText($script:settingsPath)|ConvertFrom-Json
        foreach($name in @('fontName','fontChosen','theme','backgroundId','customBackgroundPath','backgroundDim','mascotEnabled','animationsEnabled','compactCards','overlayEnabled','overlayRecentEnabled','overlayRecentCount','overlayBestEnabled')){
            if($null -ne $prefs.$name){Set-Variable -Scope Script -Name $name -Value $prefs.$name}
        }
    }catch{}
}
if($script:fontChoices -notcontains $script:fontName){$script:fontName=$script:fontChoices[0]}
if($script:theme -notin @('rose','ocean','lavender')){$script:theme='rose'}
if($script:backgroundId -notin @('cafe','lake','room','none','custom')){$script:backgroundId='cafe'}
$script:backgroundDim=[math]::Max(0,[math]::Min(90,[int]$script:backgroundDim))
$script:overlayRecentCount=[math]::Max(1,[math]::Min(5,[int]$script:overlayRecentCount))
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
    return @{map=$play.map;pp=$play.pp;accuracy=$play.accuracy;combo=$play.combo;fc=[bool]$play.fc;rank=$play.rank;stars=$play.stars;hits=$play.hitText;time=$play.time;background=$bg;mods=@($mods)}
}
function Get-OverlayState {
    $s=$script:session
    $plays=if($s){@($s.plays)}else{@()}
    $best=$plays|Sort-Object pp -Descending|Select-Object -First 1
    $gain=$null;if($s -and $null -ne $s.baseline -and $null -ne $s.latest){$gain=[math]::Round($s.latest-$s.baseline,2)}
    $seconds=0;if($s){$end=if($s.ended){[datetime]$s.ended}else{Get-Date};$seconds=[math]::Max(0,[int]($end-[datetime]$s.started).TotalSeconds)}
    $recent=@()
    if($script:overlayRecentEnabled){for($i=$plays.Count-1;$i -ge 0 -and $recent.Count -lt $script:overlayRecentCount;$i--){$recent+=Convert-OverlayScore $plays[$i]}}
    return @{showRecent=$script:overlayRecentEnabled;showBest=$script:overlayBestEnabled;recent=@($recent);best=$(if($script:overlayBestEnabled){Convert-OverlayScore $best}else{$null});animate=$script:animationsEnabled;language=$script:language;font=$script:fontName;accent=('#{0:X2}{1:X2}{2:X2}' -f [SessionTheme]::Accent.R,[SessionTheme]::Accent.G,[SessionTheme]::Accent.B);gain=$gain;fc=@($plays|Where-Object fc).Count;plays=$plays.Count;bestPp=$(if($best){$best.pp}else{$null});bestMap=$(if($best){$best.map}else{''});seconds=$seconds;ended=[bool]($s -and $s.ended)}
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
function Show-AppearanceSettings {
    $dialog=Dialog-Form (T 'Оформление и OBS' 'Appearance & OBS') 940 760
    $dialog.FormBorderStyle='FixedDialog';$dialog.MaximizeBox=$false
    $draft=@{backgroundId=$script:backgroundId;customPath=$script:customBackgroundPath}
    [void](Dialog-Label $dialog (T 'Шрифт' 'Font') 25 20 380 30)
    $font=Font-Combo $dialog 25 55 390
    $fontPreview=Dialog-Label $dialog 'osu! tracker · 200.00 pp ♡' 25 100 390 50 16
    $font.Add_SelectedIndexChanged({$fontPreview.Font=New-Object Drawing.Font([string]$font.SelectedItem,16)})
    [void](Dialog-Label $dialog (T 'Цветовая тема' 'Color theme') 25 160 390 30)
    $themes=New-Object Windows.Forms.ComboBox;$themes.Location=New-Object Drawing.Point(25,195);$themes.Size=New-Object Drawing.Size(390,32);$themes.DropDownStyle='DropDownList'
    [void]$themes.Items.AddRange([object[]]@((T 'Розовая' 'Rose'),(T 'Океан' 'Ocean'),(T 'Лаванда' 'Lavender')))
    $themes.SelectedIndex=@('rose','ocean','lavender').IndexOf($script:theme);$dialog.Controls.Add($themes)
    [void](Dialog-Label $dialog (T 'Затемнение фона' 'Background dimming') 25 245 390 30)
    $dim=New-Object Windows.Forms.TrackBar;$dim.Location=New-Object Drawing.Point(20,280);$dim.Size=New-Object Drawing.Size(395,45);$dim.Minimum=0;$dim.Maximum=90;$dim.TickFrequency=10;$dim.Value=$script:backgroundDim;$dialog.Controls.Add($dim)
    $mascotCheck=New-Object Windows.Forms.CheckBox;$mascotCheck.Text=T 'Показывать маскота' 'Show mascot';$mascotCheck.SetBounds(25,340,390,30);$mascotCheck.Checked=$script:mascotEnabled;$dialog.Controls.Add($mascotCheck)
    $voiceCheck=New-Object Windows.Forms.CheckBox;$voiceCheck.Text=T 'Японское приветствие' 'Japanese voice greeting';$voiceCheck.SetBounds(25,375,390,30);$voiceCheck.Checked=$script:voiceEnabled;$dialog.Controls.Add($voiceCheck)
    $animationCheck=New-Object Windows.Forms.CheckBox;$animationCheck.Text=T 'Анимация новых скоров' 'Animate new scores';$animationCheck.SetBounds(25,410,390,30);$animationCheck.Checked=$script:animationsEnabled;$dialog.Controls.Add($animationCheck)
    $compactCheck=New-Object Windows.Forms.CheckBox;$compactCheck.Text=T 'Компактные карточки' 'Compact score cards';$compactCheck.SetBounds(25,445,390,30);$compactCheck.Checked=$script:compactCards;$dialog.Controls.Add($compactCheck)
    [void](Dialog-Label $dialog (T 'Галерея фонов' 'Background gallery') 450 20 460 30)
    $gallery=New-Object Windows.Forms.ComboBox;$gallery.Location=New-Object Drawing.Point(450,55);$gallery.Size=New-Object Drawing.Size(460,32);$gallery.DropDownStyle='DropDownList'
    [void]$gallery.Items.AddRange([object[]]@((T 'Вечернее кафе' 'Twilight café'),(T 'Ночное озеро' 'Moonlit lake'),(T 'Уютная комната' 'Cozy room'),(T 'Без изображения' 'No wallpaper'),(T 'Моё изображение' 'My image')))
    $gallery.SelectedIndex=@('cafe','lake','room','none','custom').IndexOf($script:backgroundId);$dialog.Controls.Add($gallery)
    $picture=New-Object Windows.Forms.PictureBox;$picture.SetBounds(450,105,460,270);$picture.SizeMode='Zoom';$picture.BackColor=[SessionTheme]::PanelColor;$dialog.Controls.Add($picture)
    $updatePreview={
        $draft.backgroundId=@('cafe','lake','room','none','custom')[$gallery.SelectedIndex]
        $path=Get-MenuBackgroundPath $draft.backgroundId $draft.customPath
        $old=$picture.Image;$picture.Image=$null;if($old){$old.Dispose()}
        if($path -and [IO.File]::Exists($path)){$source=[Drawing.Image]::FromFile($path);try{$picture.Image=New-Object Drawing.Bitmap($source)}finally{$source.Dispose()}}
    }
    $gallery.Add_SelectedIndexChanged($updatePreview)
    & $updatePreview
    [void](Dialog-Button $dialog (T 'Выбрать своё изображение…' 'Choose your own image…') 450 390 460 {
        $choose=New-Object Windows.Forms.OpenFileDialog;$choose.Filter='Images (*.png;*.jpg;*.jpeg;*.bmp)|*.png;*.jpg;*.jpeg;*.bmp'
        if($choose.ShowDialog() -eq 'OK'){try{$draft.customPath=Import-MenuBackground $choose.FileName;$gallery.SelectedIndex=4;& $updatePreview}catch{[void][Windows.Forms.MessageBox]::Show($_.Exception.Message)}};$choose.Dispose()
    })
    [void](Dialog-Label $dialog (T 'PNG / JPG / BMP. Изображение хранится только на этом компьютере.' 'PNG / JPG / BMP. Your image stays on this computer.') 450 440 460 60 9)
    $obsCheck=New-Object Windows.Forms.CheckBox;$obsCheck.Text=T 'Включить оверлей для OBS' 'Enable OBS overlay';$obsCheck.SetBounds(25,515,390,30);$obsCheck.Checked=$script:overlayEnabled;$dialog.Controls.Add($obsCheck)
    $bestCheck=New-Object Windows.Forms.CheckBox;$bestCheck.Text=T 'Лучший скор сессии' 'Session best score';$bestCheck.SetBounds(450,515,460,30);$bestCheck.Checked=$script:overlayBestEnabled;$dialog.Controls.Add($bestCheck)
    $recentCheck=New-Object Windows.Forms.CheckBox;$recentCheck.Text=T 'Последние скоры:' 'Recent scores:';$recentCheck.SetBounds(25,550,280,30);$recentCheck.Checked=$script:overlayRecentEnabled;$dialog.Controls.Add($recentCheck)
    $recentCount=New-Object Windows.Forms.NumericUpDown;$recentCount.SetBounds(310,550,85,30);$recentCount.Minimum=1;$recentCount.Maximum=5;$recentCount.Value=$script:overlayRecentCount;$dialog.Controls.Add($recentCount)
    $obsInfo=Dialog-Label $dialog '' 25 590 880 45 10
    $obsInfo.Text=if($script:overlayServer){$script:overlayServer.Url}else{T 'Нажми «Применить», чтобы получить локальную ссылку.' 'Click Apply to get the local overlay URL.'}
    [void](Dialog-Button $dialog (T 'Скопировать URL для OBS' 'Copy OBS URL') 25 640 280 {
        if($script:overlayServer){[Windows.Forms.Clipboard]::SetText($script:overlayServer.Url);$obsInfo.Text=T 'Ссылка скопирована. В OBS: источник «Браузер», размер 780 × 1000.' 'URL copied. In OBS: add a Browser source, size 780 × 1000.'}
    })
    [void](Dialog-Button $dialog (T 'Открыть оверлей' 'Preview overlay') 320 640 280 {if($script:overlayServer){Start-Process $script:overlayServer.Url}})
    $apply={
        $script:fontName=[string]$font.SelectedItem;$script:fontChosen=$true;$script:theme=@('rose','ocean','lavender')[$themes.SelectedIndex]
        $script:backgroundId=$draft.backgroundId;$script:customBackgroundPath=$draft.customPath;$script:backgroundDim=$dim.Value
        $script:mascotEnabled=$mascotCheck.Checked;$script:voiceEnabled=$voiceCheck.Checked;$script:animationsEnabled=$animationCheck.Checked;$script:compactCards=$compactCheck.Checked
        $script:overlayEnabled=$obsCheck.Checked;$script:overlayBestEnabled=$bestCheck.Checked;$script:overlayRecentEnabled=$recentCheck.Checked;$script:overlayRecentCount=[int]$recentCount.Value
        if(!$script:voiceEnabled){[MascotAudio]::Stop()}
        Apply-DesktopStyle;Apply-Language
        try{Sync-Overlay}catch{$script:overlayEnabled=$false;$obsCheck.Checked=$false;[void][Windows.Forms.MessageBox]::Show((T 'Не удалось запустить оверлей: ' 'Could not start overlay: ')+$_.Exception.Message)}
        Save-Settings
        $obsInfo.Text=if($script:overlayServer){$script:overlayServer.Url+'  ·  OBS Browser source: 780 × 1000'}else{T 'Оверлей выключен' 'Overlay is off'}
    }
    $applyButton=Dialog-Button $dialog (T 'Применить' 'Apply') 655 700 120 $apply;$applyButton.Primary=$true
    [void](Dialog-Button $dialog (T 'Закрыть' 'Close') 790 700 120 {$dialog.Close()})
    [void]$dialog.ShowDialog($form)
    if($picture.Image){$picture.Image.Dispose()};$dialog.Dispose()
}
function Show-SessionHistory {
    $window=Dialog-Form (T 'История сессий' 'Session history') 1150 740
    $window.MinimumSize=New-Object Drawing.Size(1000,650)
    $sessions=New-Object Windows.Forms.ListBox;$sessions.SetBounds(20,65,270,590);$sessions.Anchor='Top,Bottom,Left';$sessions.DisplayMember='label'
    $sessions.BackColor=[SessionTheme]::PanelColor;$sessions.ForeColor=[Drawing.Color]::White;$sessions.BorderStyle='None';$sessions.ItemHeight=30;$window.Controls.Add($sessions)
    [void](Dialog-Label $window (T 'Сохранённые сессии' 'Saved sessions') 20 20 270 30 13)
    $info=Dialog-Label $window (T 'Выбери сессию слева.' 'Select a session on the left.') 315 20 810 100 11;$info.Anchor='Top,Left,Right'
    $scores=New-Object ScoreCards;$scores.SetBounds(315,130,815,525);$scores.Anchor='Top,Bottom,Left,Right';$scores.ApplyCardStyle($script:fontName,110,$false)
    $scores.Add_ScoreClicked($openScoreHandler);$window.Controls.Add($scores)
    $selected=@{session=$null}
    $reload={
        $sessions.Items.Clear()
        if($script:session){Save-Session}
        $items=New-Object 'System.Collections.Generic.List[object]'
        foreach($file in Get-ChildItem -LiteralPath $dataDir -Filter '*.json'){
            $date=$file.LastWriteTime
            try{$reader=[IO.File]::OpenText($file.FullName);try{for($lineIndex=0;$lineIndex -lt 12 -and !$reader.EndOfStream;$lineIndex++){$line=$reader.ReadLine();if($line -match '"started"\s*:\s*"([^"]+)"'){$date=[datetime]$Matches[1];break}}}finally{$reader.Dispose()}}catch{}
            $items.Add([pscustomobject]@{label=$date.ToString('dd.MM.yyyy HH:mm')+' · '+$file.BaseName.Substring(0,[math]::Min(6,$file.BaseName.Length));path=$file.FullName;date=$date})
        }
        foreach($item in $items|Sort-Object date -Descending){[void]$sessions.Items.Add($item)}
        if($sessions.Items.Count -gt 0){$sessions.SelectedIndex=0}else{$info.Text=T 'История пока пустая.' 'No saved sessions yet.'}
    }
    $sessions.Add_SelectedIndexChanged({
        if(!$sessions.SelectedItem){return}
        try{
            $s=[IO.File]::ReadAllText($sessions.SelectedItem.path)|ConvertFrom-Json
            if(!$s.started -or $null -eq $s.plays){throw 'Invalid session file'}
            $selected.session=$s;$plays=@($s.plays);$best=$plays|Sort-Object pp -Descending|Select-Object -First 1
            $gain=if($null -ne $s.baseline -and $null -ne $s.latest){'{0:+0.00;-0.00;0.00}' -f ($s.latest-$s.baseline)}else{'—'}
            $fc=@($plays|Where-Object fc).Count
            $info.Text=([datetime]$s.started).ToString('dd.MM.yyyy HH:mm')+'  ·  '+(T 'Просмотр истории (текущая сессия продолжает записываться)' 'History view (your current session keeps recording)')+"`r`n"+(T "Прохождений: $($plays.Count)   FC: $fc   Прирост профиля: $gain pp" "Plays: $($plays.Count)   FC: $fc   Profile gain: $gain pp")+"`r`n"+(T "Лучший плей: $($best.pp) pp  ·  $($best.map)" "Best play: $($best.pp) pp  ·  $($best.map)")
            $entries=New-Object 'System.Collections.Generic.List[ScoreEntry]';foreach($p in $plays|Sort-Object pp -Descending){$entries.Add((Make-ScoreEntry $p))}
            $scores.ReplaceCards($entries.ToArray());$scores.TopIndex=0
        }catch{$selected.session=$null;$scores.ClearCards();$scores.Invalidate();$info.Text=T 'Не удалось прочитать эту сессию.' 'Could not read this session.'}
    })
    $refresh=Dialog-Button $window (T 'Обновить список' 'Refresh list') 20 680 270 $reload;$refresh.Anchor='Bottom,Left'
    $export=Dialog-Button $window (T 'Экспорт выбранной сессии' 'Export selected session') 315 680 290 {
        if(!$selected.session){return};$save=New-Object Windows.Forms.SaveFileDialog;$save.Filter='CSV (*.csv)|*.csv';$save.FileName='osu-session.csv'
        if($save.ShowDialog() -eq 'OK'){$selected.session.plays|Export-Csv -LiteralPath $save.FileName -NoTypeInformation -Encoding UTF8};$save.Dispose()
    };$export.Anchor='Bottom,Left'
    & $reload
    [void]$window.ShowDialog($form);$window.Dispose()
}
