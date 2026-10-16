$script:language='ru'
$script:languageChosen=$false
$script:settingsPath=Join-Path $PSScriptRoot 'settings.json'
if([IO.File]::Exists($script:settingsPath)){
    try{$saved=[IO.File]::ReadAllText($script:settingsPath) | ConvertFrom-Json;if($saved.language -in @('ru','en')){$script:language=$saved.language;$script:languageChosen=$true}}catch{}
}
function T([string]$ru,[string]$en){if($script:language -eq 'en'){return $en};return $ru}
function Save-Settings {
    $settings=@{}
    if([IO.File]::Exists($script:settingsPath)){try{$old=[IO.File]::ReadAllText($script:settingsPath)|ConvertFrom-Json;foreach($prop in $old.PSObject.Properties){$settings[$prop.Name]=$prop.Value}}catch{}}
    $settings.language=$script:language
    $settings.voiceEnabled=$script:voiceEnabled
    foreach($name in @('fontName','fontChosen','theme','backgroundId','customBackgroundPath','backgroundDim','mascotEnabled','animationsEnabled','compactCards','overlayEnabled','overlayRecentEnabled','overlayRecentCount','overlayBestEnabled')){
        $value=Get-Variable -Scope Script -Name $name -ErrorAction SilentlyContinue
        if($value){$settings[$name]=$value.Value}
    }
    $settings | ConvertTo-Json | Set-Content -LiteralPath $script:settingsPath -Encoding UTF8
}
function Select-Language {
    $dialog=New-Object Windows.Forms.Form
    $dialog.Text='Language / Язык';$dialog.ClientSize=New-Object Drawing.Size(470,210)
    $dialog.StartPosition='CenterScreen';$dialog.FormBorderStyle='FixedDialog';$dialog.MaximizeBox=$false;$dialog.MinimizeBox=$false
    $dialog.BackColor=[Drawing.Color]::FromArgb(23,20,29);$dialog.ForeColor=[Drawing.Color]::White
    $dialog.Font=New-Object Drawing.Font('Comic Sans MS',12)
    [SessionTheme]::RoundWindow($dialog)
    $caption=New-Object Windows.Forms.Label;$caption.Text='Choose your language / Выбери язык';$caption.Location=New-Object Drawing.Point(25,30);$caption.Size=New-Object Drawing.Size(425,60);$dialog.Controls.Add($caption)
    foreach($entry in @(@('Русский','ru',25),@('English','en',250))){
        $button=New-Object SessionButton;$button.Text=$entry[0];$button.Tag=$entry[1];$button.Primary=$true
        $button.Location=New-Object Drawing.Point($entry[2],115);$button.Size=New-Object Drawing.Size(195,50)
        $button.Add_Click({param($sender,$e) $script:language=[string]$sender.Tag;$script:languageChosen=$true;$sender.FindForm().DialogResult='OK'})
        $dialog.Controls.Add($button)
    }
    $result=$dialog.ShowDialog();$dialog.Dispose()
    if($result -ne 'OK'){return $false}
    Save-Settings
    return $true
}
