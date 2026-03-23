param(
    [Alias("n")]
    [switch]$DryRun,
    [switch]$NoReview,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: script/update.ps1 [-DryRun|-n] [-NoReview]"
    exit 0
}

# Detect VCS type
$repodir = $PSScriptRoot | Split-Path -Parent
$use_jj = 0
if ((Test-Path "$repodir/.jj") -and (Get-Command jj -ErrorAction SilentlyContinue)) {
    $use_jj = 1
    $vcs = "jj"
} else {
    $vcs = "git"
}

if ($DryRun) {
    Write-Host "Dry run: skipping chezmoi upgrade"
} else {
    Write-Host "Updating chezmoi"
    chezmoi upgrade
}

if ($DryRun) {
    Write-Host "Dry run: skipping dotfiles repository sync"
} else {
    Write-Host "Updating dotfiles repository"
    if ($use_jj -eq 1) {
        Set-Location $repodir
        jj git fetch
        # Don't use chezmoi update (it would try to use git), just apply
        chezmoi apply -R
    } else {
        chezmoi update -R
    }
}

function Get-OldOpVersions {
    param([string]$FilePath)
    $result = @{}
    if (-not (Test-Path $FilePath)) { return $result }
    $content = Get-Content $FilePath -Raw
    $currentPlatform = $null
    foreach ($line in ($content -split "`n")) {
        if ($line -match '^\s{4}(\w+):\s*$') {
            $currentPlatform = $Matches[1]
        } elseif ($currentPlatform -and $line -match '^\s{6}version:\s*"([^"]+)"') {
            $result[$currentPlatform] = $Matches[1]
            $currentPlatform = $null  # version: always precedes sha256: in each block
        }
    }
    return $result
}

function Update-OpCliVersions {
    $url = "https://app-updates.agilebits.com/product_history/CLI2"
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing
    } catch {
        Write-Warning "Warning: unable to fetch op CLI version from $url"
        return
    }

    $file = Join-Path $repodir "home/.chezmoidata/versions.yml"
    $oldVersions = Get-OldOpVersions -FilePath $file

    $regex = [regex]'https://cache\.agilebits\.com/dist/1P/op2/pkg/v([^/]+)/op_(linux|freebsd)_(amd64|arm64)_v\1\.zip'
    $matches = $regex.Matches($response.Content)
    if ($matches.Count -eq 0) {
        Write-Warning "Warning: unable to find op CLI links in $url"
        return
    }

    $latest = @{}
    foreach ($m in $matches) {
        if ($m.Groups[1].Value -match "beta") {
            continue
        }
        $platform = $m.Groups[2].Value
        $arch = $m.Groups[3].Value
        $key = "$platform/$arch"
        if (-not $latest.ContainsKey($key)) {
            $latest[$key] = @{
                Version = $m.Groups[1].Value
                Link = $m.Groups[0].Value
            }
        }
    }

    $platformVersion = @{}
    foreach ($key in $latest.Keys) {
        $platform = $key.Split('/')[0]
        if (-not $platformVersion.ContainsKey($platform)) {
            $platformVersion[$platform] = $latest[$key].Version
        }
    }

    function Get-Sha256 {
        param([Parameter(Mandatory=$true)][string]$Path)
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $stream = [System.IO.File]::OpenRead($Path)
        try {
            $hash = $sha.ComputeHash($stream)
        } finally {
            $stream.Dispose()
            $sha.Dispose()
        }
        ($hash | ForEach-Object { $_.ToString("x2") }) -join ""
    }

    $checksums = @{
        linux = @{}
        freebsd = @{}
    }

    foreach ($key in $latest.Keys) {
        $platform, $arch = $key.Split('/')
        $link = $latest[$key].Link
        $tmp = [System.IO.Path]::GetTempFileName()
        try {
            Invoke-WebRequest -Uri $link -OutFile $tmp -UseBasicParsing
            $checksums[$platform][$arch] = Get-Sha256 -Path $tmp
        } finally {
            Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        }
    }

    $lines = @()
    $lines += "versions:"
    $lines += "  op_cli:"
    foreach ($platform in @("linux", "freebsd")) {
        if (-not $platformVersion.ContainsKey($platform)) {
            continue
        }
        $lines += "    $platform:"
        $lines += "      version: `"$($platformVersion[$platform])`""
        $lines += "      sha256:"
        foreach ($arch in ($checksums[$platform].Keys | Sort-Object)) {
            $lines += "        $arch: `"$($checksums[$platform][$arch])`""
        }
    }

    $lines -join "`n" | Out-File -FilePath $file -Encoding utf8

    foreach ($platform in (($oldVersions.Keys + $platformVersion.Keys) | Sort-Object -Unique)) {
        $oldVer = if ($oldVersions.ContainsKey($platform)) { "v$($oldVersions[$platform])" } else { "(new)" }
        $newVer = if ($platformVersion.ContainsKey($platform)) { "v$($platformVersion[$platform])" } else { "(removed)" }
        if ($oldVer -ne $newVer) {
            Write-Output "op_cli ${platform}: $oldVer → $newVer"
        }
    }
}

if ($DryRun) {
    Write-Host "Dry run: skipping op CLI version update"
} else {
    $opChanges = Update-OpCliVersions
    if ($opChanges) {
        Write-Host "Updated op CLI versions and checksums"
        $indentedChanges = $opChanges | ForEach-Object { "  $_" }
        $commitMessage = (@(
            'Update op CLI versions'
            ''
        ) + $indentedChanges) -join "`n"
        $commitMessage | Out-File -FilePath "$repodir\.git\COMMIT_EDITMSG" -Encoding utf8
        Write-Host "Committing op CLI version update"
        if ($use_jj -eq 1) {
            $commitMsg = Get-Content "$repodir\.git\COMMIT_EDITMSG" -Raw
            Set-Location $repodir
            jj commit -m $commitMsg home/.chezmoidata/versions.yml
        } else {
            Set-Location $repodir
            git commit -F .git/COMMIT_EDITMSG home/.chezmoidata/versions.yml
        }
    }
}

$agentExternalsUpdater = Join-Path $repodir "scripts/update-externals-lock.py"
if (Test-Path $agentExternalsUpdater) {
    Write-Host "Checking for externals updates"
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        $changesFile = [System.IO.Path]::GetTempFileName()
        try {
            # Step 1: Resolve (always, even in dry-run)
            $resolveOutput = uv run $agentExternalsUpdater --dry-run --json
            $resolveExit = $LASTEXITCODE

            if ($resolveExit -eq 2) {
                Write-Host "No externals updates available"
            } elseif ($resolveExit -ne 0) {
                Write-Warning "Warning: externals resolution failed (exit $resolveExit); skipping"
            } else {
                # Write JSON to temp file
                $resolveOutput | Out-File -FilePath $changesFile -Encoding utf8
                $changes = Get-Content $changesFile -Raw | ConvertFrom-Json

                # Step 2: Review (unless --no-review)
                if (-not $NoReview) {
                    foreach ($c in $changes) {
                        if ($c.review -ne $false) {
                            $ref = if ($c.ref) { $c.ref } else { "main" }
                            uv run (Join-Path $repodir "scripts/show-git-changes.py") `
                                $c.repo $c.old_sha $c.new_sha --name $c.id --ref $ref
                        }
                    }
                }

                # Step 3: Decision point
                if ($DryRun) {
                    Write-Host "Dry run: externals review complete, not applying"
                } else {
                    $apply = $true
                    if (-not $NoReview -and -not [Console]::IsInputRedirected) {
                        $decided = $false
                        while (-not $decided) {
                            $answer = Read-Host "Apply externals updates? [Y/n/d]"
                            switch -Regex ($answer) {
                                '^$|^[Yy]' { $decided = $true }
                                '^[Nn]' { $apply = $false; $decided = $true }
                                '^[Dd]' {
                                    foreach ($c in $changes) {
                                        if ($c.review -ne $false) {
                                            $ref = if ($c.ref) { $c.ref } else { "main" }
                                            uv run (Join-Path $repodir "scripts/show-git-changes.py") `
                                                $c.repo $c.old_sha $c.new_sha --name $c.id --ref $ref --diff
                                        }
                                    }
                                }
                                default { Write-Host "Please answer Y, n, or d" }
                            }
                        }
                    }

                    if ($apply) {
                        uv run $agentExternalsUpdater --apply-resolved $changesFile
                        chezmoi apply -R

                        $commitLines = @("Update pinned externals", "")
                        foreach ($c in $changes) {
                            $old = $c.old_sha.Substring(0, 7)
                            $new = $c.new_sha.Substring(0, 7)
                            $ref = if ($c.ref) { $c.ref } else { "main" }
                            $commitLines += "  $($c.id): $old -> $new ($ref)"
                        }
                        $commitMessage = $commitLines -join "`n"
                        $commitMessage | Out-File -FilePath "$repodir\.git\COMMIT_EDITMSG" -Encoding utf8

                        Write-Host "Committing pinned externals update"
                        if ($use_jj -eq 1) {
                            $commitMsg = Get-Content "$repodir\.git\COMMIT_EDITMSG" -Raw
                            Set-Location $repodir
                            jj commit -m $commitMsg home/.chezmoidata/externals-lock.yml
                        } else {
                            Set-Location $repodir
                            git commit -F .git/COMMIT_EDITMSG home/.chezmoidata/externals-lock.yml
                        }
                    } else {
                        Write-Host "Skipping externals update"
                        chezmoi apply -R
                    }
                }
            }
        } finally {
            if (Test-Path $changesFile) {
                Remove-Item $changesFile -Force
            }
        }
    } else {
        Write-Warning "Warning: uv not available; skipping externals update"
    }
}

if ($DryRun) {
    Write-Host "Dry run: skipping Home Manager update"
    exit 0
}

# Exit if we don't have the nix command
if (-not (Get-Command nix -ErrorAction SilentlyContinue)) {
    Write-Warning "Warning: nix must be installed to update Home Manager packages"
    exit 1
}

function Invoke-Nix {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$Args
    )
    & nix --experimental-features 'nix-command flakes' @Args
}

function Invoke-HM {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$Args
    )
    if (-not (Get-Command home-manager -ErrorAction SilentlyContinue)) {
        Invoke-Nix @("run", "--no-write-lock-file", "github:nix-community/home-manager/", "--") + $Args
    } else {
        & home-manager @Args
    }
}

function Home-Manager-Build {
    param (
        [string]$Configuration = $env:USER
    )
    $package = "$HOME/.config/home-manager#homeConfigurations.$Configuration.activationPackage"
    Invoke-Nix @("build", "--no-link", $package)
    Home-Manager-NVD $Configuration
}

function Home-Manager-NVD {
    param (
        [string]$Configuration = $env:USER
    )
    $generation = Invoke-HM @("generations") | Select-String -Pattern "generation" | Select-Object -First 1 | ForEach-Object { $_.Line.Split()[6] }
    if ($generation) {
        $package = "$HOME/.config/home-manager#homeConfigurations.$Configuration.activationPackage"
        $new_generation = Invoke-Nix @("path-info", $package) 2>&1 | Out-String
        if ($new_generation -and $generation -ne $new_generation) {
            if (Get-Command nvd -ErrorAction SilentlyContinue) {
                nvd diff $generation $new_generation
            }
        }
    }
}

if (-not $env:HOME) {
    $env:HOME = $env:USERPROFILE
}

$sourcedir = "$HOME/.config/home-manager"

$tmpfile = [System.IO.Path]::GetTempFileName()
try {
    if (-not (Get-Command nix -ErrorAction SilentlyContinue)) {
        Write-Error "Error: nix must be installed to update Home Manager packages"
        exit 1
    }

    Write-Host "Applying existing Home Manager configuration prior to update"
    chezmoi apply $sourcedir
    Invoke-HM @("switch")

    Write-Host "Updating Home Manager packages"
    Set-Location $sourcedir
    $nixUpdateOutput = Invoke-Nix @("flake", "update", "--override-input", "nixpkgs", "github:NixOS/nixpkgs/nixos-unstable") 2>&1
    $nixUpdateFiltered = $nixUpdateOutput -notmatch '(^warning:|searching up|into the Git cache)'
    $nixUpdateFiltered | Out-File -FilePath $tmpfile -Encoding utf8

    if (-not (Get-Content $tmpfile)) {
        Write-Host "No update to the home-manager inputs available"
        exit 0
    }

    chezmoi re-add flake.lock

    $commitMessage = @(
        'Update Home Manager packages'
        ''
        ($nixUpdateFiltered | ForEach-Object { "  $_" -replace '#(\d+)', '$1' })
    ) -join "`n"

    $commitMessage | Out-File -FilePath "$repodir/.git/COMMIT_EDITMSG" -Encoding utf8

    $homeManagerBuildOutput = Home-Manager-Build | Tee-Object -Variable buildOutput
    $buildOutput | Out-File -FilePath $tmpfile -Encoding utf8
    $buildOutput | Write-Host

    if (Get-Content $tmpfile) {
        if ($buildOutput -match "No version or selection state changes.") {
            Write-Host "No version or selection state changes; reverting flake update and skipping commit"
            git -C $repodir checkout HEAD -- home/dot_config/home-manager/private_flake.lock
            chezmoi apply (Join-Path $sourcedir "flake.lock")
            exit 0
        }

        $packageChanges = @(
            ''
            ($buildOutput | ForEach-Object { "  $_" -replace '#(\d+)', '- $1' })
        ) -join "`n"

        Add-Content -Path "$repodir/.git/COMMIT_EDITMSG" -Value $packageChanges
    }

    Write-Host "Committing Home Manager updates"
    Set-Location $repodir
    if ($use_jj -eq 1) {
        $commitMsg = Get-Content "$repodir/.git/COMMIT_EDITMSG" -Raw
        jj commit -m $commitMsg home/dot_config/home-manager/private_flake.lock
    } else {
        git commit -F .git/COMMIT_EDITMSG home/dot_config/home-manager/private_flake.lock
    }

    Invoke-HM @("switch")
    Invoke-HM @("expire-generations", "-30 days")
    nix-env --delete-generations old
} catch {
    Write-Error "An error occurred: $_"
    Set-Location $sourcedir
    if ($use_jj -eq 1) {
        # jj automatically handles uncommitted changes
    } else {
        git checkout HEAD -- home/dot_config/home-manager/private_flake.lock
        chezmoi apply "$sourcedir/private_flake.lock"
    }
} finally {
    # Clean up the temporary file
    if (Test-Path $tmpfile) {
        Remove-Item $tmpfile -Force
    }
}
