#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows Entwicklungsumgebung Setup-Skript
.DESCRIPTION
    Installiert und konfiguriert alle notwendigen Tools fuer eine
    DevOps/Softwareentwicklungs-Umgebung via Chocolatey.
    Aktualisiert sich automatisch von GitHub vor der Ausfuehrung.
.NOTES
    Einmaliger Start (als Administrator):
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/r0b1nr31nh4rdt/windows-setup-dev-ops/main/setup-windows.ps1" -UseBasicParsing | Invoke-Expression
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# SELBST-UPDATE VON GITHUB
# ---------------------------------------------------------------------------
$GITHUB_RAW_URL = "https://raw.githubusercontent.com/r0b1nr31nh4rdt/windows-setup-dev-ops/main/setup-windows.ps1"

# Nur updaten wenn das Skript als Datei ausgefuehrt wird (nicht via Invoke-Expression)
$scriptPath = $MyInvocation.MyCommand.Path

if ($scriptPath) {
    Write-Host ""
    Write-Host "  [UPDATE] Pruefe auf neue Version von GitHub ..." -ForegroundColor Cyan

    try {
        $remoteScript = (Invoke-WebRequest -Uri $GITHUB_RAW_URL -UseBasicParsing -TimeoutSec 10).Content
        $localScript  = Get-Content -Path $MyInvocation.MyCommand.Path -Raw

        if ($remoteScript -ne $localScript) {
            Write-Host "  [UPDATE] Neue Version gefunden - aktualisiere Skript ..." -ForegroundColor Yellow
            Set-Content -Path $MyInvocation.MyCommand.Path -Value $remoteScript -Encoding UTF8
            Write-Host "  [UPDATE] Skript aktualisiert - starte neu ..." -ForegroundColor Green
            Write-Host ""
            # Neu starten mit aktualisierter Version
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $MyInvocation.MyCommand.Path
            exit
        } else {
            Write-Host "  [UPDATE] Bereits aktuell." -ForegroundColor Green
        }
    } catch {
        Write-Host "  [UPDATE] GitHub nicht erreichbar - fahre mit lokaler Version fort." -ForegroundColor Magenta
    }
}

# ---------------------------------------------------------------------------
# HILFSFUNKTIONEN
# ---------------------------------------------------------------------------

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Text)
    Write-Host "  --> $Text" -ForegroundColor Yellow
}

function Write-OK {
    param([string]$Text)
    Write-Host "  [OK] $Text" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Text)
    Write-Host "  [!!] $Text" -ForegroundColor Magenta
}

function Install-ChocoPackage {
    param([string]$Package, [string]$Label = "")
    $name = if ($Label) { $Label } else { $Package }
    Write-Step "Installiere $name ..."
    try {
        choco install $Package -y --no-progress 2>&1 | Out-Null
        Write-OK "$name installiert"
    } catch {
        Write-Warn "$name konnte nicht installiert werden: $_"
    }
}

function Add-ToPath {
    param([string]$NewPath)
    $current = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($current -notlike "*$NewPath*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$current;$NewPath", "Machine")
        $env:PATH += ";$NewPath"
        Write-OK "PATH erweitert: $NewPath"
    } else {
        Write-Warn "Bereits im PATH: $NewPath"
    }
}

# ---------------------------------------------------------------------------
# CHOCOLATEY INSTALLIEREN (falls nicht vorhanden)
# ---------------------------------------------------------------------------

Write-Header "Chocolatey pruefen / installieren"

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Step "Chocolatey wird installiert ..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # Profil neu laden damit choco verfuegbar ist
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1" -ErrorAction SilentlyContinue
    refreshenv
    Write-OK "Chocolatey installiert"
} else {
    Write-OK "Chocolatey bereits vorhanden: $(choco --version)"
    Write-Step "Chocolatey wird aktualisiert ..."
    choco upgrade chocolatey -y --no-progress 2>&1 | Out-Null
}

# ---------------------------------------------------------------------------
# GRUNDLEGENDE TOOLS
# ---------------------------------------------------------------------------

Write-Header "Grundlegende Tools"

Install-ChocoPackage "git"             "Git"
Install-ChocoPackage "gh"              "GitHub CLI"
Install-ChocoPackage "curl"            "curl"
Install-ChocoPackage "wget"            "wget"
Install-ChocoPackage "7zip"            "7-Zip"
Install-ChocoPackage "jq"             "jq (JSON-Parser)"
Install-ChocoPackage "neovim"          "Neovim"
Install-ChocoPackage "ripgrep"         "ripgrep (rg)"
Install-ChocoPackage "fzf"             "fzf (Fuzzy Finder)"
Install-ChocoPackage "bat"             "bat (besseres cat)"
Install-ChocoPackage "tree-extended"   "tree"
Install-ChocoPackage "less"            "less"

# ---------------------------------------------------------------------------
# SHELLS & TERMINAL
# ---------------------------------------------------------------------------

Write-Header "Shell & Terminal"

Install-ChocoPackage "powershell-core"   "PowerShell 7"
Install-ChocoPackage "windowsterminal"   "Windows Terminal"
Install-ChocoPackage "oh-my-posh"        "Oh My Posh (Prompt)"
Install-ChocoPackage "nerd-fonts-hack"   "Hack Nerd Font"

# ---------------------------------------------------------------------------
# SPRACHEN & RUNTIMES
# ---------------------------------------------------------------------------

Write-Header "Python"

Install-ChocoPackage "python"         "Python 3"
Install-ChocoPackage "pipx"           "pipx"

Write-Header "Node.js / JavaScript"

Install-ChocoPackage "nvm"            "nvm (Node Version Manager)"
Install-ChocoPackage "pnpm"           "pnpm"

Write-Header "Rust"

Install-ChocoPackage "rustup.install" "Rustup (Rust Toolchain Manager)"

Write-Header "Go"

Install-ChocoPackage "golang"         "Go"

Write-Header "C / C++"

Install-ChocoPackage "mingw"          "MinGW (GCC fuer Windows)"
Install-ChocoPackage "cmake"          "CMake"
Install-ChocoPackage "ninja"          "Ninja Build"

# ---------------------------------------------------------------------------
# DEVOPS & INFRASTRUKTUR
# ---------------------------------------------------------------------------

Write-Header "DevOps & Infrastruktur"

Install-ChocoPackage "docker-desktop"         "Docker Desktop"
Install-ChocoPackage "docker-compose"         "Docker Compose"
Install-ChocoPackage "kubernetes-cli"         "kubectl"
Install-ChocoPackage "k9s"                    "k9s (Kubernetes TUI)"
Install-ChocoPackage "helm"                   "Helm"
Install-ChocoPackage "terraform"              "Terraform"
Install-ChocoPackage "terraform-docs"         "terraform-docs"
Install-ChocoPackage "packer"                 "Packer"
Install-ChocoPackage "ansible"                "Ansible"
Install-ChocoPackage "awscli"                 "AWS CLI"
Install-ChocoPackage "azure-cli"              "Azure CLI"
Install-ChocoPackage "gcloudsdk"              "Google Cloud SDK"

# ---------------------------------------------------------------------------
# EDITOREN & IDEs
# ---------------------------------------------------------------------------

Write-Header "Editoren & IDEs"

Install-ChocoPackage "vscode"         "Visual Studio Code"
Install-ChocoPackage "jetbrains-toolbox" "JetBrains Toolbox"

# ---------------------------------------------------------------------------
# DATENBANKEN & CLIENTS
# ---------------------------------------------------------------------------

Write-Header "Datenbank-Tools"

Install-ChocoPackage "dbeaver"        "DBeaver (Universal DB Client)"
Install-ChocoPackage "postgresql"     "PostgreSQL"
Install-ChocoPackage "redis-64"       "Redis"

# ---------------------------------------------------------------------------
# NETZWERK & API
# ---------------------------------------------------------------------------

Write-Header "Netzwerk & API"

Install-ChocoPackage "postman"        "Postman"
Install-ChocoPackage "insomnia-rest-api-client" "Insomnia"
Install-ChocoPackage "nmap"           "nmap"
Install-ChocoPackage "wireshark"      "Wireshark"
Install-ChocoPackage "putty"          "PuTTY"
Install-ChocoPackage "winscp"         "WinSCP"
Install-ChocoPackage "openssh"        "OpenSSH"

# ---------------------------------------------------------------------------
# SONSTIGES / PRODUKTIVITAET
# ---------------------------------------------------------------------------

Write-Header "Produktivitaet"

Install-ChocoPackage "gsudo"          "gsudo (sudo fuer Windows)"
Install-ChocoPackage "everything"     "Everything (Dateisuche)"
Install-ChocoPackage "keepassxc"      "KeePassXC"
Install-ChocoPackage "tailscale"      "Tailscale (VPN)"

# ---------------------------------------------------------------------------
# PATH EINTRAEGE SICHERSTELLEN
# ---------------------------------------------------------------------------

Write-Header "PATH konfigurieren"

$pathEntries = @(
    "C:\Program Files\Git\cmd",
    "C:\Program Files\Git\bin",
    "C:\Python3\Scripts",
    "C:\Python3",
    "C:\Program Files\nodejs",
    "C:\Go\bin",
    "$env:USERPROFILE\.cargo\bin",
    "C:\Program Files\mingw-w64\x86_64-13.2.0-posix-seh-rt_v11-rev0\mingw64\bin",
    "C:\Program Files\CMake\bin",
    "C:\Program Files\Terraform",
    "C:\Program Files\Helm",
    "$env:APPDATA\pnpm"
)

foreach ($p in $pathEntries) {
    if (Test-Path $p) {
        Add-ToPath $p
    }
}

# ---------------------------------------------------------------------------
# WSL2 INSTALLIEREN
# ---------------------------------------------------------------------------

Write-Header "WSL2 installieren"

$wslStatus = wsl --status 2>&1
if ($wslStatus -like "*nicht installiert*" -or $wslStatus -like "*not installed*" -or $LASTEXITCODE -ne 0) {
    Write-Step "WSL2 wird aktiviert ..."
    wsl --install --no-distribution
    Write-Warn "WSL2 wurde installiert. Bitte nach dem Neustart 'wsl --install -d Ubuntu' ausfuehren."
} else {
    Write-OK "WSL2 bereits vorhanden"
    Write-Step "WSL2 wird aktualisiert ..."
    wsl --update 2>&1 | Out-Null
}

# ---------------------------------------------------------------------------
# WINDOWS EXPLORER EINSTELLUNGEN
# ---------------------------------------------------------------------------

Write-Header "Windows Explorer konfigurieren"

Write-Step "Dateiendungen anzeigen ..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "HideFileExt" -Value 0
Write-OK "Dateiendungen sichtbar"

Write-Step "Versteckte Dateien anzeigen ..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "Hidden" -Value 1
Write-OK "Versteckte Dateien sichtbar"

Write-Step "Geschuetzte Systemdateien anzeigen ..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "ShowSuperHidden" -Value 1
Write-OK "Systemdateien sichtbar"

Write-Step "Vollstaendigen Pfad in Titelleiste anzeigen ..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "FullPath" -Value 1
Write-OK "Vollstaendiger Pfad in Titelleiste aktiv"

Write-Step "Explorer startet im 'Dieser PC'-Modus ..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "LaunchTo" -Value 1
Write-OK "Explorer oeffnet 'Dieser PC'"

# ---------------------------------------------------------------------------
# POWERSHELL-PROFIL EINRICHTEN
# ---------------------------------------------------------------------------

Write-Header "PowerShell-Profil einrichten"

$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

$profileContent = @'
# ===========================================================================
# PowerShell Profil - automatisch generiert
# ===========================================================================

# Oh My Posh Prompt (Theme: jandedobbeleer - aenderbar)
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression
}

# Chocolatey Profil (fuer refreshenv)
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path $ChocolateyProfile) {
    Import-Module $ChocolateyProfile
}

# ---------------------------------------------------------------------------
# ALIASE
# ---------------------------------------------------------------------------

# Navigation
Set-Alias ll Get-ChildItem
function la { Get-ChildItem -Force }
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function ~ { Set-Location $HOME }

# Git Shortcuts
function gs  { git status }
function ga  { git add $args }
function gc  { git commit -m $args }
function gp  { git push $args }
function gl  { git pull $args }
function gco { git checkout $args }
function gb  { git branch $args }
function glog { git log --oneline --graph --decorate --all }

# Docker Shortcuts
function dps  { docker ps $args }
function dpsa { docker ps -a $args }
function di   { docker images $args }
function dex  { docker exec -it $args }

# Netzwerk
function myip { (Invoke-WebRequest -Uri "https://api.ipify.org").Content }
function ports { netstat -ano | findstr LISTENING }

# Tools
function which { Get-Command $args | Select-Object -ExpandProperty Source }
function reload { . $PROFILE }
function edit-profile { nvim $PROFILE }

# ---------------------------------------------------------------------------
# UMGEBUNGSVARIABLEN
# ---------------------------------------------------------------------------

$env:EDITOR = "nvim"
$env:GIT_EDITOR = "nvim"

# Go
$env:GOPATH = "$HOME\go"
$env:PATH += ";$env:GOPATH\bin"

# Rust (cargo)
$env:PATH += ";$env:USERPROFILE\.cargo\bin"

# pnpm
$env:PNPM_HOME = "$env:APPDATA\pnpm"
$env:PATH += ";$env:PNPM_HOME"

# ---------------------------------------------------------------------------
# WILLKOMMENS-INFO
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "  PS7 bereit  " -ForegroundColor Cyan -NoNewline
Write-Host " | " -ForegroundColor DarkGray -NoNewline
Write-Host "$(Get-Date -Format 'dddd, dd.MM.yyyy HH:mm')" -ForegroundColor Gray
Write-Host ""
'@

Set-Content -Path $PROFILE -Value $profileContent -Encoding UTF8
Write-OK "PowerShell-Profil erstellt: $PROFILE"

# ---------------------------------------------------------------------------
# GIT GLOBAL KONFIGURATION
# ---------------------------------------------------------------------------

Write-Header "Git Grundkonfiguration"

Write-Step "Git-Einstellungen setzen ..."
git config --global core.autocrlf input
git config --global core.editor "nvim"
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global color.ui auto
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.lg "log --oneline --graph --decorate --all"
Write-OK "Git konfiguriert (Name/Email bitte manuell setzen)"
Write-Warn "  --> git config --global user.name  'Dein Name'"
Write-Warn "  --> git config --global user.email 'deine@email.de'"

# ---------------------------------------------------------------------------
# ABSCHLUSS
# ---------------------------------------------------------------------------

Write-Header "Setup abgeschlossen!"

Write-Host ""
Write-Host "  Naechste Schritte:" -ForegroundColor White
Write-Host "  1. Terminal neu starten (oder 'refreshenv' ausfuehren)" -ForegroundColor Gray
Write-Host "  2. Git-Name und -Email setzen (siehe oben)" -ForegroundColor Gray
Write-Host "  3. WSL2-Distribution installieren: wsl --install -d Ubuntu" -ForegroundColor Gray
Write-Host "  4. Node.js installieren: nvm install --lts" -ForegroundColor Gray
Write-Host "  5. Rust initialisieren: rustup default stable" -ForegroundColor Gray
Write-Host "  6. Docker Desktop starten und WSL2-Integration aktivieren" -ForegroundColor Gray
Write-Host "  7. Oh My Posh Theme anpassen: edit-profile" -ForegroundColor Gray
Write-Host ""
Write-Host "  Viel Erfolg!" -ForegroundColor Cyan
Write-Host ""
