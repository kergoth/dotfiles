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

function Invoke-Nix {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$Args
    )
    & nix --experimental-features 'nix-command flakes' @Args
    if ($LASTEXITCODE -ne 0) {
        throw "nix failed with exit code $LASTEXITCODE"
    }
}

function Invoke-HM {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$Args
    )
    if (-not (Get-Command home-manager -ErrorAction SilentlyContinue)) {
        Invoke-Nix (@("run", "--no-write-lock-file", "github:nix-community/home-manager/", "--") + $Args)
    } else {
        & home-manager @Args
    }
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

function Home-Manager-Build {
    param (
        [string]$Configuration = $env:USER
    )
    $package = "$HOME/.config/home-manager#homeConfigurations.$Configuration.activationPackage"
    Invoke-Nix @("build", "--no-link", $package)
    Home-Manager-NVD $Configuration
}

if ($DryRun) {
    Write-Host "Dry run: checking chezmoi upgrade"
    try {
        chezmoi upgrade --dry-run
    } catch {
        # Match the shell script behavior and keep going on upgrade failures.
    }
} else {
    Write-Host "Updating chezmoi"
    try {
        chezmoi upgrade
    } catch {
        # Match the shell script behavior and keep going on upgrade failures.
    }
}

if ($DryRun) {
    Write-Host "Dry run: checking dotfiles repository"
    Set-Location $repodir
    if ($use_jj -eq 1) {
        jj git fetch
        Write-Host "Dry run: fetched jj-backed dotfiles repository, not applying"
    } else {
        git symbolic-ref -q HEAD *> $null
        if ($LASTEXITCODE -eq 0) {
            git fetch
            $upstream = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2> $null
            if ($LASTEXITCODE -eq 0 -and $upstream) {
                $incoming = git rev-list --count "HEAD..$upstream"
                if ($LASTEXITCODE -eq 0 -and [int]$incoming -gt 0) {
                    Write-Host "Dry run: $incoming incoming dotfiles commit(s) from $upstream"
                } else {
                    Write-Host "Dry run: dotfiles repository has no upstream updates"
                }
            } else {
                Write-Host "Dry run: dotfiles branch has no upstream, fetched only"
            }
        } else {
            git fetch
            Write-Host "Dry run: detached dotfiles repository, fetched only"
        }
    }
} else {
    Write-Host "Updating dotfiles repository"
    if ($use_jj -eq 1) {
        Set-Location $repodir
        jj git fetch
        # Don't use chezmoi update (it would try to use git), just apply
        chezmoi apply -R
    } else {
        Set-Location $repodir
        git symbolic-ref -q HEAD *> $null
        if ($LASTEXITCODE -eq 0) {
            chezmoi update -R
        } else {
            Write-Warning "Warning: Not on a branch, skipping git pull. Fetching only."
            git fetch
            chezmoi apply -R
        }
    }
}

function Update-OpCliVersions {
    param (
        [string[]]$UpdateArgs = @()
    )
    $python = Get-Command python3 -ErrorAction SilentlyContinue
    if (-not $python) {
        Write-Warning "Warning: python3 not available; skipping op CLI version update"
        return $null
    }

    & $python.Source (Join-Path $repodir "scripts/update-op-cli-versions.py") @UpdateArgs
    if ($LASTEXITCODE -ne 0) {
        throw "update-op-cli-versions.py failed with exit code $LASTEXITCODE"
    }
}

function Update-ContainerBaseImageDigests {
    param (
        [string[]]$UpdateArgs = @()
    )
    $python = Get-Command python3 -ErrorAction SilentlyContinue
    if (-not $python) {
        Write-Warning "Warning: python3 not available; skipping container pin update"
        return $null
    }

    & $python.Source (Join-Path $repodir "scripts/update-container-pins.py") @UpdateArgs
    if ($LASTEXITCODE -ne 0) {
        throw "update-container-pins.py failed with exit code $LASTEXITCODE"
    }
}

if ($DryRun) {
    try {
        $opChanges = Update-OpCliVersions -UpdateArgs @("--dry-run")
    } catch {
        Write-Warning "Warning: op CLI version dry-run failed; skipping"
        $opChanges = $null
    }
    if ($opChanges) {
        Write-Host "Dry run: op CLI version changes available"
        $opChanges | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Host "Dry run: no op CLI version changes"
    }
} else {
    try {
        $opChanges = Update-OpCliVersions
    } catch {
        Write-Warning "Warning: op CLI version update failed; skipping"
        $opChanges = $null
    }
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

if ($DryRun) {
    $containerError = $false
    try {
        $containerChanges = Update-ContainerBaseImageDigests -UpdateArgs @("--dry-run")
    } catch {
        Write-Warning "Warning: container pin dry-run had errors; continuing"
        $containerError = $true
        $containerChanges = $null
    }
    if ($containerChanges) {
        if ($containerError) {
            Write-Host "Dry run: container pin partial changes available"
        } else {
            Write-Host "Dry run: container pin changes available"
        }
        $containerChanges | ForEach-Object { Write-Host "  $_" }
    } elseif (-not $containerError) {
        Write-Host "Dry run: no container pin changes"
    }
} else {
    $containerError = $false
    try {
        $containerChanges = Update-ContainerBaseImageDigests
    } catch {
        Write-Warning "Warning: container pin update had errors; continuing"
        $containerError = $true
        $containerChanges = $null
    }
    if ($containerChanges -and $containerError) {
        Write-Host "Container pin partial changes:"
        $containerChanges | ForEach-Object { Write-Host "  $_" }
    }
    if ($containerChanges -and -not $containerError) {
        Write-Host "Updated container pins"
        $indentedChanges = $containerChanges | ForEach-Object { "  $_" }
        $commitMessage = (@(
            'Update container pins'
            ''
        ) + $indentedChanges) -join "`n"
        $commitMessage | Out-File -FilePath "$repodir\.git\COMMIT_EDITMSG" -Encoding utf8
        Write-Host "Committing container pin update"
        if ($use_jj -eq 1) {
            $commitMsg = Get-Content "$repodir\.git\COMMIT_EDITMSG" -Raw
            Set-Location $repodir
            jj commit -m $commitMsg home/.chezmoidata/container-lock.yml test/containers
        } else {
            Set-Location $repodir
            git commit -F .git/COMMIT_EDITMSG home/.chezmoidata/container-lock.yml test/containers
        }
    }
}

$gitLockUpdater = Join-Path $repodir "scripts/update-git-lock.py"
if (Test-Path $gitLockUpdater) {
    Write-Host "Checking for Git source updates"
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        $changesFile = [System.IO.Path]::GetTempFileName()
        try {
            # Step 1: Resolve (always, even in dry-run)
            $resolveOutput = uv run $gitLockUpdater --dry-run --json
            $resolveExit = $LASTEXITCODE

            if ($resolveExit -eq 2) {
                Write-Host "No Git source updates available"
            } elseif ($resolveExit -ne 0) {
                Write-Warning "Warning: Git source resolution failed (exit $resolveExit); skipping"
            } else {
                # Write JSON to temp file
                $resolveOutput | Out-File -FilePath $changesFile -Encoding utf8
                $changes = Get-Content $changesFile -Raw | ConvertFrom-Json

                # Step 2: Review (unless --no-review)
                if (-not $NoReview) {
                    foreach ($c in $changes) {
                        if ($c.review -ne $false) {
                            $ref = if ($c.kind -eq 'tag') { $c.new_sha } elseif ($c.ref) { $c.ref } else { "main" }
                            $reviewArgs = @($c.repo, $c.old_sha, $c.new_sha, '--name', $c.id, '--ref', $ref)
                            if ($c.kind) { $reviewArgs += @('--kind', $c.kind) }
                            if ($c.tag_pattern) { $reviewArgs += @('--tag-pattern', $c.tag_pattern) }
                            if ($c.review_note) { $reviewArgs += @('--review-note', $c.review_note) }
                            if ($c.ai_agent) { $reviewArgs += @('--ai-agent', $c.ai_agent) }
                            if ($c.ai_model) { $reviewArgs += @('--ai-model', $c.ai_model) }
                            if ($c.ai_timeout) { $reviewArgs += @('--ai-timeout', [string]$c.ai_timeout) }
                            foreach ($reviewPath in @($c.review_paths)) {
                                if ($reviewPath) {
                                    $reviewArgs += @('--review-paths', $reviewPath)
                                }
                            }
                            uv run (Join-Path $repodir "scripts/show-git-changes.py") @reviewArgs
                        }
                    }
                }

                # Step 3: Decision point
                if ($DryRun) {
                    Write-Host "Dry run: Git source review complete, not applying"
                } else {
                    $apply = $true
                    if (-not $NoReview -and -not [Console]::IsInputRedirected) {
                        $decided = $false
                        while (-not $decided) {
                            $answer = Read-Host "Apply Git source updates? [Y/n/d]"
                            switch -Regex ($answer) {
                                '^$|^[Yy]' { $decided = $true }
                                '^[Nn]' { $apply = $false; $decided = $true }
                                '^[Dd]' {
                                    foreach ($c in $changes) {
                                        if ($c.review -ne $false) {
                                            $ref = if ($c.kind -eq 'tag') { $c.new_sha } elseif ($c.ref) { $c.ref } else { "main" }
                                            $reviewArgs = @($c.repo, $c.old_sha, $c.new_sha, '--name', $c.id, '--ref', $ref, '--diff-only')
                                            if ($c.kind) { $reviewArgs += @('--kind', $c.kind) }
                                            if ($c.tag_pattern) { $reviewArgs += @('--tag-pattern', $c.tag_pattern) }
                                            if ($c.review_note) { $reviewArgs += @('--review-note', $c.review_note) }
                                            if ($c.ai_agent) { $reviewArgs += @('--ai-agent', $c.ai_agent) }
                                            if ($c.ai_model) { $reviewArgs += @('--ai-model', $c.ai_model) }
                                            if ($c.ai_timeout) { $reviewArgs += @('--ai-timeout', [string]$c.ai_timeout) }
                                            foreach ($reviewPath in @($c.review_paths)) {
                                                if ($reviewPath) {
                                                    $reviewArgs += @('--review-paths', $reviewPath)
                                                }
                                            }
                                            uv run (Join-Path $repodir "scripts/show-git-changes.py") @reviewArgs
                                        }
                                    }
                                }
                                default { Write-Host "Please answer Y, n, or d" }
                            }
                        }
                    }

                    if ($apply) {
                        uv run $gitLockUpdater --apply-resolved $changesFile
                        $fetchLockUpdater = Join-Path $repodir "scripts/update-fetch-lock.py"
                        if (Test-Path $fetchLockUpdater) {
                            uv run $fetchLockUpdater
                        }
                        try {
                            chezmoi apply -R
                        } catch {
                            # Match the shell script behavior and keep going.
                        }

                        Set-Location $repodir
                        git diff --quiet -- home/.chezmoidata/fetch-lock.yml 2> $null
                        $title = if ($LASTEXITCODE -eq 0) { "Update Git lock" } else { "Update source locks" }
                        $commitLines = @($title, "", "Git lock updates:")
                        foreach ($c in $changes) {
                            $suffix = if ($c.tag_pattern) { " [$($c.tag_pattern)]" } else { "" }
                            if ($c.kind -eq 'tag') {
                                $old = if ($c.old_sha) { $c.old_sha } else { '(new)' }
                                $new = $c.new_sha
                                $commitLines += "  $($c.id): $old -> $new$suffix"
                            } else {
                                $old = $c.old_sha.Substring(0, 7)
                                $new = $c.new_sha.Substring(0, 7)
                                $ref = if ($c.ref) { $c.ref } else { "main" }
                                $commitLines += "  $($c.id): $old -> $new ($ref)$suffix"
                            }
                        }
                        $fetchUpdates = @'
import re
import subprocess
import sys

repo = sys.argv[1]
path = "home/.chezmoidata/fetch-lock.yml"
line_re = re.compile(r"^[+-]  ([^:]+): \"([^\"]*)\"$")

result = subprocess.run(
    ["git", "-C", repo, "diff", "--no-color", "--unified=0", "--", path],
    capture_output=True,
    text=True,
    check=False,
)

old_map = {}
new_map = {}
for line in result.stdout.splitlines():
    if line.startswith("--- ") or line.startswith("+++ "):
        continue
    match = line_re.match(line)
    if not match:
        continue
    key, value = match.groups()
    if line[0] == "-":
        old_map[key] = value
    elif line[0] == "+":
        new_map[key] = value

for key in sorted(set(old_map) | set(new_map)):
    old_v = old_map.get(key)
    new_v = new_map.get(key)
    if old_v != new_v:
        old_s = (old_v or "(new)")[:12]
        new_s = (new_v or "(removed)")[:12]
        print(f"{key}: {old_s} -> {new_s}")
'@ | uv run python3 - $repodir
                        if ($LASTEXITCODE -eq 0 -and $fetchUpdates) {
                            $commitLines += ""
                            $commitLines += "Fetch lock updates:"
                            foreach ($line in ($fetchUpdates -split "`r?`n")) {
                                if ($line) {
                                    $commitLines += "  $line"
                                }
                            }
                        }
                        $commitMessage = $commitLines -join "`n"
                        $commitMessage | Out-File -FilePath "$repodir\.git\COMMIT_EDITMSG" -Encoding utf8

                        Write-Host "Committing Git lock update"
                        if ($use_jj -eq 1) {
                            $commitMsg = Get-Content "$repodir\.git\COMMIT_EDITMSG" -Raw
                            Set-Location $repodir
                            jj commit -m $commitMsg home/.chezmoidata/git-lock.yml home/.chezmoidata/fetch-lock.yml
                        } else {
                            Set-Location $repodir
                            git commit -F .git/COMMIT_EDITMSG home/.chezmoidata/git-lock.yml home/.chezmoidata/fetch-lock.yml
                        }
                    } else {
                        Write-Host "Skipping Git source update"
                        try {
                            chezmoi apply -R
                        } catch {
                            # Match the shell script behavior and keep going.
                        }
                    }
                }
            }
        } finally {
            if (Test-Path $changesFile) {
                Remove-Item $changesFile -Force
            }
        }
    } else {
        Write-Warning "Warning: uv not available; skipping Git source update"
    }
}

function Get-HomeManagerGenerationPath {
    $generation = Invoke-HM @("generations") | Select-String -Pattern "/nix/store/" | Select-Object -First 1
    if ($generation) {
        $match = [regex]::Match($generation.Line, "/nix/store/\S+")
        if ($match.Success) {
            return $match.Value
        }
    }
    return $null
}

function Get-HomeManagerPackagePath {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FlakeRef,
        [switch]$FallbackToGeneration
    )
    try {
        Invoke-Nix @("build", "--no-link", $FlakeRef) | Out-Null
        $path = Invoke-Nix @("path-info", $FlakeRef) 2> $null
        if ($LASTEXITCODE -eq 0 -and $path) {
            return ($path | Select-Object -First 1).ToString().Trim()
        }
    } catch {
    }
    if ($FallbackToGeneration) {
        return Get-HomeManagerGenerationPath
    }
    return $null
}

if ($DryRun) {
    if (-not (Get-Command nix -ErrorAction SilentlyContinue)) {
        Write-Warning "Warning: nix must be installed to preview Home Manager packages"
        exit 0
    }

    if (-not $env:HOME) {
        $env:HOME = $env:USERPROFILE
    }
    $configuration = if ($env:USER) { $env:USER } else { $env:USERNAME }
    $sourceDir = Join-Path $env:HOME ".config/home-manager"
    $candidateDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $previousLocation = Get-Location

    try {
        Copy-Item -Path $sourceDir -Destination $candidateDir -Recurse -Force

        $beforeRef = "$sourceDir#homeConfigurations.$configuration.activationPackage"
        $beforePath = Get-HomeManagerPackagePath -FlakeRef $beforeRef -FallbackToGeneration

        Set-Location $candidateDir
        Invoke-Nix @("flake", "update", "nixpkgs", "nixpkgs-unstable")

        $afterRef = "path:$candidateDir#homeConfigurations.$configuration.activationPackage"
        $afterPath = Get-HomeManagerPackagePath -FlakeRef $afterRef

        if ($beforePath -and $afterPath -and $beforePath -ne $afterPath) {
            if (Get-Command nvd -ErrorAction SilentlyContinue) {
                nvd diff $beforePath $afterPath
            } else {
                Write-Host "Dry run: Home Manager generation would change: $beforePath -> $afterPath"
            }
        } elseif ($beforePath -and $afterPath) {
            Write-Host "Dry run: no Home Manager package updates"
        } else {
            Write-Warning "Warning: unable to compare Home Manager package paths"
        }
    } finally {
        Set-Location $previousLocation
        if (Test-Path $candidateDir) {
            Remove-Item $candidateDir -Recurse -Force
        }
    }
    exit 0
}

# Exit if we don't have the nix command
if (-not (Get-Command nix -ErrorAction SilentlyContinue)) {
    Write-Warning "Warning: nix must be installed to update Home Manager packages"
    exit 1
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
    $nixUpdateOutput = Invoke-Nix @("flake", "update", "nixpkgs", "nixpkgs-unstable") 2>&1
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
