# Detect VCS type
$repodir = $PSScriptRoot | Split-Path -Parent
$use_jj = 0
if ((Test-Path "$repodir/.jj") -and (Get-Command jj -ErrorAction SilentlyContinue)) {
    $use_jj = 1
    $vcs = "jj"
} else {
    $vcs = "git"
}

Write-Host "Updating chezmoi"
chezmoi upgrade

Write-Host "Updating dotfiles repository"
if ($use_jj -eq 1) {
    Set-Location $repodir
    jj git fetch
    # Don't use chezmoi update (it would try to use git), just apply
    chezmoi apply -R
} else {
    chezmoi update -R
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
        'Home Manager Update'
        ''
        '  Home Manager input changes:'
        ''
        ($nixUpdateFiltered | ForEach-Object { "    $_" -replace '#(\d+)', '$1' })
    ) -join "`n"

    $commitMessage | Out-File -FilePath "$repodir/.git/COMMIT_EDITMSG" -Encoding utf8

    $homeManagerBuildOutput = Home-Manager-Build | Tee-Object -Variable buildOutput
    $buildOutput | Out-File -FilePath $tmpfile -Encoding utf8
    $buildOutput | Write-Host

    if (Get-Content $tmpfile) {
        if ($buildOutput -match "No version or selection state changes.") {
            Write-Host "No update to the home-manager packages available"
            exit 0
        }

        $packageChanges = @(
            ''
            '  Home Manager packages changes:'
            ''
            ($buildOutput | ForEach-Object { "    $_" -replace '#(\d+)', '- $1' })
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
