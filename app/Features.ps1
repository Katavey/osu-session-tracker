Add-Type -AssemblyName System.Net.Http
$script:topChecks=New-Object 'System.Collections.Generic.List[object]'
[Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$script:topHttp=New-Object Net.Http.HttpClient
$script:topHttp.Timeout=[timespan]::FromSeconds(12)
$script:topHttp.DefaultRequestHeaders.UserAgent.ParseAdd('OsuSessionTracker/1.6')
$script:topHttp.DefaultRequestHeaders.Add('X-Requested-With','XMLHttpRequest')
$script:topRequest=$null
$script:topJob=$null
$script:noticeUntil=[datetime]::MinValue
$script:voiceEnabled=$true
$script:settingsPath=Join-Path $PSScriptRoot 'settings.json'
if([IO.File]::Exists($script:settingsPath)){
    try{$settings=[IO.File]::ReadAllText($script:settingsPath) | ConvertFrom-Json;if($null -ne $settings.voiceEnabled){$script:voiceEnabled=[bool]$settings.voiceEnabled}}catch{}
}
function Play-WelcomeVoice {
    if(!$script:voiceEnabled){return}
    $audioPath=Join-Path $PSScriptRoot 'assets/welcome-ja.wav'
    if([IO.File]::Exists($audioPath)){[void][MascotAudio]::Play($audioPath)}
}
function Toggle-Voice {
    $script:voiceEnabled=!$script:voiceEnabled
    if(!$script:voiceEnabled){[MascotAudio]::Stop()}
    if($voiceButton){$voiceButton.Text=if($script:voiceEnabled){T 'Голос: вкл' 'Voice: on'}else{T 'Голос: выкл' 'Voice: off'}}
    try{Save-Settings}catch{}
}
function Queue-TopCheck($p,$player) {
    if($player -le 0 -or ($p.server -and $p.server -notin @('ppy.sh','osu.ppy.sh'))){return}
    $script:topChecks.Add([pscustomobject]@{play=$p;player=$player;sessionId=$script:session.id;attempt=0;due=(Get-Date).AddSeconds(8)})
}
function Find-TopPosition($p,$scores) {
    $position=0
    foreach($score in @($scores) | Select-Object -First 5){
        $position++
        if([long]$score.beatmap.id -ne [long]$p.beatmapId){continue}
        if($p.scoreId -gt 0 -and @($score.id,$score.legacy_score_id,$score.legacy_id) -contains $p.scoreId){return $position}
        # When tosu has no online ID, require score, map, mods and a close timestamp.
        $date=if($score.ended_at){$score.ended_at}else{$score.created_at}
        if(!$date){continue}
        try{$seconds=[math]::Abs(([datetimeoffset]::Parse($date)-[datetimeoffset]::Parse($p.time)).TotalSeconds)}catch{continue}
        $total=if($null -ne $score.legacy_total_score){$score.legacy_total_score}else{$score.score}
        $mods=@($score.mods | ForEach-Object {if($_ -is [string]){$_}else{$_.acronym}}) -join ''
        $actual=([ScoreCards]::ParseMods($mods) | Where-Object {$_ -ne 'NM'} | Sort-Object) -join ','
        $expected=([ScoreCards]::ParseMods($p.mods) | Where-Object {$_ -ne 'NM'} | Sort-Object) -join ','
        if($p.score -gt 0 -and $total -eq $p.score -and $seconds -le 120 -and $actual -eq $expected -and $score.max_combo -eq $p.combo){return $position}
    }
    return 0
}
function Show-MascotNotice($heading,$message,$seconds=7) {
    if((Get-Variable -Scope Script -Name mascotEnabled -ErrorAction SilentlyContinue) -and !$script:mascotEnabled){return}
    if(!$noticePanel){return}
    $noticeTitle.Text=$heading;$noticeText.Text=$message
    $noticePanel.Left=[math]::Max(12,($form.ClientSize.Width-$noticePanel.Width)/2)
    $noticePanel.Top=[math]::Max(12,($form.ClientSize.Height-$noticePanel.Height)/2)
    $noticePanel.Visible=$true;$noticePanel.BringToFront()
    $script:noticeUntil=(Get-Date).AddSeconds($seconds)
}
function Tick-Features {
    if($noticePanel -and $noticePanel.Visible -and (Get-Date) -ge $script:noticeUntil){$noticePanel.Visible=$false}
    if($script:topRequest -and $script:topRequest.IsCompleted){
        $job=$script:topJob
        $request=$script:topRequest
        $script:topRequest=$null;$script:topJob=$null
        try{
            $body=$request.GetAwaiter().GetResult()
            if($job.sessionId -ne $script:session.id){return}
            $scores=$body | ConvertFrom-Json
            if($body.TrimStart() -notlike '[[]*'){throw 'Не удалось прочитать топ профиля'}
            if($hint){$hint.Text=T 'Топ-5 проверяется по профилю osu! • pp карт — расчёт tosu.' 'Top 5 verified against your osu! profile • play pp calculated by tosu.'}
            $pos=Find-TopPosition $job.play $scores
            if($pos -gt 0){
                $job.play | Add-Member topPosition $pos -Force
                Save-Session
                Show-MascotNotice (T "Топ-$pos профиля!" "Profile top #$pos!") (T "Ура! Твой плей на $($job.play.pp) pp вошёл в топ-5! Так держать!" "Yay! Your $($job.play.pp) pp play made your profile top 5! Keep it up!") 10
                $job.attempt=99
            }
        }catch{if($hint){$hint.Text=T 'Топ-5: сайт пока недоступен. Трекинг сессии продолжается.' 'Top 5: website unavailable. Session tracking continues.'}}
        $script:topRequest=$null;$script:topJob=$null
        if($job.attempt -lt 3){$job.due=(Get-Date).AddSeconds(25);$script:topChecks.Add($job)}
    }
    if(!$script:topRequest){
        $job=$script:topChecks | Where-Object {$_.due -le (Get-Date)} | Select-Object -First 1
        if($job){
            [void]$script:topChecks.Remove($job)
            if($job.player -ne $script:session.player -or $job.sessionId -ne $script:session.id){return}
            $job.attempt++
            $mode=@('osu','taiko','fruits','mania')[[math]::Max(0,[math]::Min(3,[int]$job.play.mode))]
            $script:topJob=$job
            $script:topRequest=$script:topHttp.GetStringAsync("https://osu.ppy.sh/users/$($job.player)/scores/best?mode=$mode&limit=5&offset=0")
        }
    }
}
