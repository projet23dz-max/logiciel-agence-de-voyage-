@echo off
title PALM TOURS - installation
echo.
echo  PALM TOURS : telechargement de la derniere version...
echo  (ne fermez pas cette fenetre)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s = (Get-Content -LiteralPath '%~f0' -Raw) -split '#=PS=#'; Invoke-Expression $s[2]"
echo.
pause
exit /b
#=PS=#
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$base = 'https://raw.githubusercontent.com/projet23dz-max/logiciel-agence-de-voyage-/main/'
try {
  $m = (Invoke-WebRequest ($base + 'latest.json?t=' + [DateTime]::Now.Ticks) -UseBasicParsing).Content | ConvertFrom-Json
  Write-Host (' Version ' + $m.version + ' (' + [math]::Round($m.size / 1MB) + ' Mo)')
  $dir = Join-Path $env:USERPROFILE 'Downloads'
  if (-not (Test-Path $dir)) { $dir = $env:TEMP }
  $out = Join-Path $dir $m.file
  $f = [IO.File]::Create($out)
  try {
    $n = 0
    foreach ($p in $m.parts) {
      $n++
      Write-Host (' Partie ' + $n + ' / ' + $m.parts.Count + ' ...')
      $tmp = $out + '.tmp'
      Invoke-WebRequest ($base + $p.name) -OutFile $tmp -UseBasicParsing
      $b = [IO.File]::ReadAllBytes($tmp)
      $f.Write($b, 0, $b.Length)
      Remove-Item $tmp
    }
  } finally { $f.Close() }
  $h = (Get-FileHash $out -Algorithm SHA256).Hash.ToLower()
  if ($h -ne $m.sha256) {
    Write-Host ' ERREUR : fichier abime pendant le telechargement. Relancez ce fichier.' -ForegroundColor Red
    exit 1
  }
  Write-Host (' OK : ' + $out) -ForegroundColor Green
  Write-Host ' Fermez PALM TOURS, puis repondez OUI a la fenetre de Windows.' -ForegroundColor Green
  Start-Process -FilePath $out
} catch {
  Write-Host (' ERREUR : ' + $_.Exception.Message) -ForegroundColor Red
  Write-Host ' Verifiez Internet, puis relancez ce fichier.' -ForegroundColor Red
}
