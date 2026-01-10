Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
$NetworksDir = if ($env:NNUE_DIR) { $env:NNUE_DIR } else { Join-Path $RepoRoot "src\networks" }

$Files = @(
  "nn-2962dca31855.nnue",
  "nn-37f18f62d772.nnue"
)

$BaseUrls = @(
  "https://raw.githubusercontent.com/official-stockfish/networks/master",
  "https://media.githubusercontent.com/media/official-stockfish/networks/master",
  "https://tests.stockfishchess.org/api/nn"
)

function Test-NnueFile {
  param([string]$Path)
  if (-not (Test-Path $Path)) {
    return $false
  }
  $bytes = [System.IO.File]::ReadAllBytes($Path)
  if ($bytes.Length -lt 4) {
    return $false
  }
  $magic = [System.Text.Encoding]::ASCII.GetString($bytes[0..3])
  return $magic -eq "NNUE"
}

New-Item -ItemType Directory -Force -Path $NetworksDir | Out-Null

foreach ($file in $Files) {
  $dest = Join-Path $NetworksDir $file
  if (Test-Path $dest) {
    if (Test-NnueFile -Path $dest) {
      Write-Host "Found $file in $NetworksDir"
      continue
    }
    Write-Host "Removing invalid $file from $NetworksDir"
    Remove-Item -Force $dest
  }

  $downloaded = $false
  foreach ($base in $BaseUrls) {
    $url = "$base/$file"
    $tmp = "$dest.tmp"
    Write-Host "Downloading $file from $url ..."
    try {
      Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
      if (Test-NnueFile -Path $tmp) {
        Move-Item -Force $tmp $dest
        Write-Host "Saved $file to $NetworksDir"
        $downloaded = $true
        break
      } else {
        Write-Error "Downloaded $file is invalid."
      }
    } catch {
      if (Test-Path $tmp) {
        Remove-Item -Force $tmp
      }
    }
  }

  if (-not $downloaded) {
    throw "Failed to download $file."
  }
}
