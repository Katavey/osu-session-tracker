param([ValidateSet('stable','lazer')][string]$Client='stable',[Parameter(Mandatory=$true)][string]$TosuExePath)
$ErrorActionPreference='Stop'
if(!(Test-Path -LiteralPath $TosuExePath -PathType Leaf)){throw 'Supply the path to official tosu.exe'}
$root=Join-Path $PSScriptRoot ('dist/osu-session-tracker-v2.1-'+$Client)
[IO.Directory]::CreateDirectory($root) | Out-Null
$app=Join-Path $root 'app'
[IO.Directory]::CreateDirectory($app) | Out-Null
$source=Join-Path $PSScriptRoot 'app'
foreach($name in @('Tracker.ps1','Features.ps1','Localization.ps1','Desktop.ps1','Feed.cs','Overlay.cs','Theme.cs')){Copy-Item -LiteralPath (Join-Path $source $name) -Destination $app -Force}
Copy-Item -LiteralPath (Join-Path $source 'assets') -Destination $app -Recurse -Force
[IO.File]::WriteAllText((Join-Path $app 'client.txt'),$Client)
$tosu=Join-Path $root 'tosu'
[IO.Directory]::CreateDirectory($tosu) | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem,System.Drawing
$tosuFile=Join-Path $tosu 'tosu.exe'
Copy-Item -LiteralPath $TosuExePath -Destination $tosuFile -Force
foreach($name in @('LICENSE.txt','SOURCE.txt')){Copy-Item -LiteralPath (Join-Path $PSScriptRoot ('third-party/tosu/'+$name)) -Destination $tosu -Force}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'README.md') -Destination (Join-Path $root 'README.txt') -Force
$iconPath=Join-Path $root 'tracker.ico'
$bitmap=New-Object Drawing.Bitmap(64,64)
$graphics=[Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode='AntiAlias'
$graphics.Clear([Drawing.Color]::Transparent)
$brush=New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(239,105,164))
$graphics.FillEllipse($brush,2,2,60,60)
$font=New-Object Drawing.Font('Comic Sans MS',19,[Drawing.FontStyle]::Bold)
$graphics.DrawString('FC',$font,[Drawing.Brushes]::White,9,16)
$icon=[Drawing.Icon]::FromHandle($bitmap.GetHicon())
$file=[IO.File]::Create($iconPath);$icon.Save($file);$file.Dispose()
$graphics.Dispose();$bitmap.Dispose();$brush.Dispose();$font.Dispose()
$compiler=(Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe')
$automation=[System.Management.Automation.PSObject].Assembly.Location
$exeName=if($Client -eq 'lazer'){'OsuSessionTrackerLazer.exe'}else{'OsuSessionTracker.exe'}
$exe=Join-Path $root $exeName
& $compiler /nologo /target:winexe /platform:x64 /optimize+ "/out:$exe" "/win32icon:$iconPath" /reference:System.Windows.Forms.dll "/reference:$automation" (Join-Path $PSScriptRoot 'src/Launcher.cs')
if($LASTEXITCODE -ne 0){throw 'Compilation failed'}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'src/Launcher.cs') -Destination (Join-Path $root 'Launcher-source.cs') -Force
'Built '+$exe
