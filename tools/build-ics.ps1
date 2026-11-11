# Builds egu27-hs410.ics from the tasks-data JSON block in index.html.
# Run after editing tasks:  powershell -ExecutionPolicy Bypass -File tools/build-ics.ps1
# Timed deadlines become a 30-minute event ending at the deadline; everything else is all-day.
param(
  [string]$Html = (Join-Path $PSScriptRoot '..\index.html'),
  [string]$Out  = (Join-Path $PSScriptRoot '..\egu27-hs410.ics')
)
$ErrorActionPreference = 'Stop'
$inv  = [System.Globalization.CultureInfo]::InvariantCulture
$utf8 = New-Object System.Text.UTF8Encoding($false)

$text = [System.IO.File]::ReadAllText((Resolve-Path $Html), $utf8)
$m = [regex]::Match($text, '<script type="application/json" id="tasks-data">([\s\S]*?)</script>')
if (-not $m.Success) { throw 'tasks-data block not found in index.html' }
$data = $m.Groups[1].Value | ConvertFrom-Json

function Esc([string]$s) { $s.Replace('\', '\\').Replace(';', '\;').Replace(',', '\,').Replace("`r", '').Replace("`n", '\n') }

# RFC 5545 folding: lines at most 75 octets, continuation lines start with one space.
function Fold([string]$line) {
  $sb = New-Object System.Text.StringBuilder
  $n = 0
  foreach ($ch in $line.ToCharArray()) {
    $b = $utf8.GetByteCount([string]$ch)
    if ($n + $b -gt 74) { [void]$sb.Append("`r`n "); $n = 1 }
    [void]$sb.Append($ch); $n += $b
  }
  $sb.ToString()
}
function DateOnly([string]$iso) { $iso.Replace('-', '') }
function NextDay([string]$iso) { [datetime]::ParseExact($iso, 'yyyy-MM-dd', $inv).AddDays(1).ToString('yyyyMMdd', $inv) }
function Utc([datetime]$d) { $d.ToString("yyyyMMdd'T'HHmmss'Z'", $inv) }

$stamp = Utc ((Get-Date).ToUniversalTime())
$L = New-Object System.Collections.Generic.List[string]
$L.Add('BEGIN:VCALENDAR')
$L.Add('VERSION:2.0')
$L.Add('PRODID:-//HS4.10 conveners//EGU27 convener calendar//EN')
$L.Add('CALSCALE:GREGORIAN')
$L.Add('METHOD:PUBLISH')
$L.Add('X-WR-CALNAME:EGU27 HS4.10 conveners')
$L.Add('X-WR-CALDESC:' + (Esc 'Convener tasks and EGU27 deadlines for session HS4.10.'))
$L.Add('REFRESH-INTERVAL;VALUE=DURATION:P1D')
$L.Add('X-PUBLISHED-TTL:P1D')

foreach ($t in $data.tasks) {
  $end = if ($t.e) { [string]$t.e } else { [string]$t.s }
  $tag = switch ($t.k) { 'deadline' { 'Deadline: ' } 'milestone' { 'FYI: ' } 'optional' { 'Optional: ' } default { '' } }
  $src = if ($t.src -eq 'egu') { 'EGU date' } else { 'Team target (suggested date)' }
  $desc = (@($t.d) -join "`n") + "`n`n" + $src
  foreach ($lk in @($t.links)) { if ($lk) { $desc += "`n" + $lk[0] + ': ' + $lk[1] } }
  $desc += "`n`nChecklist: " + $data.site

  $L.Add('BEGIN:VEVENT')
  $L.Add('UID:' + $t.id + '@egu27-hs410')
  $L.Add('DTSTAMP:' + $stamp)
  if ($t.utc) {
    $u = [DateTimeOffset]::Parse([string]$t.utc, $inv).UtcDateTime
    $L.Add('DTSTART:' + (Utc $u.AddMinutes(-30)))
    $L.Add('DTEND:' + (Utc $u))
  } else {
    $L.Add('DTSTART;VALUE=DATE:' + (DateOnly $t.s))
    $L.Add('DTEND;VALUE=DATE:' + (NextDay $end))
    $L.Add('TRANSP:TRANSPARENT')
  }
  $L.Add('SUMMARY:' + (Esc ('HS4.10 ' + $tag + $t.title + $(if ($t.t) { ' (' + $t.t + ')' } else { '' }))))
  $L.Add('DESCRIPTION:' + (Esc $desc))
  $L.Add('URL:' + $data.site)
  if ($t.src -eq 'egu' -and ($t.k -eq 'deadline' -or $t.k -eq 'task') -and -not $t.asap) {
    $L.Add('BEGIN:VALARM')
    $L.Add('ACTION:DISPLAY')
    $L.Add('DESCRIPTION:' + (Esc ('HS4.10: ' + $t.title)))
    $L.Add('TRIGGER:' + $(if ($t.utc) { '-P1D' } else { '-P2D' }))
    $L.Add('END:VALARM')
  }
  $L.Add('END:VEVENT')
}
$L.Add('END:VCALENDAR')

$body = (($L | ForEach-Object { Fold $_ }) -join "`r`n") + "`r`n"
[System.IO.File]::WriteAllText($Out, $body, $utf8)
Write-Output ("Wrote {0} events to {1}" -f @($data.tasks).Count, $Out)
