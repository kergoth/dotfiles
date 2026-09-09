#requires -Version 7.0

function ConvertFrom-TerminalHexColor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Color
    )

    if ($Color -notmatch '^#(?<hex>[0-9A-Fa-f]{3}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$') {
        return $null
    }

    $hex = $Matches.hex
    if ($hex.Length -eq 3) {
        $hex = -join ($hex.ToCharArray() | ForEach-Object { "$_$_" })
    }

    # Windows Terminal also uses #RRGGBBAA in a few settings. Alpha does not
    # affect the requested RGB value, so ignore it if present.
    if ($hex.Length -eq 8) {
        $hex = $hex.Substring(0, 6)
    }

    [pscustomobject]@{
        PSTypeName = 'Terminal.BackgroundRgb'
        R          = [Convert]::ToInt32($hex.Substring(0, 2), 16)
        G          = [Convert]::ToInt32($hex.Substring(2, 2), 16)
        B          = [Convert]::ToInt32($hex.Substring(4, 2), 16)
        Hex        = "#$($hex.ToUpperInvariant())"
    }
}

function ConvertFrom-Osc11Response {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Response
    )

    if ($Response -notmatch 'rgb:(?<r>[0-9A-Fa-f]{1,4})/(?<g>[0-9A-Fa-f]{1,4})/(?<b>[0-9A-Fa-f]{1,4})') {
        return $null
    }

    function Convert-Component([string] $Value) {
        $raw = [Convert]::ToInt32($Value, 16)
        $max = [math]::Pow(16, $Value.Length) - 1
        [int] [math]::Round(($raw * 255.0) / $max)
    }

    $r = Convert-Component $Matches.r
    $g = Convert-Component $Matches.g
    $b = Convert-Component $Matches.b

    [pscustomobject]@{
        PSTypeName = 'Terminal.BackgroundRgb'
        R          = $r
        G          = $g
        B          = $b
        Hex        = '#{0:X2}{1:X2}{2:X2}' -f $r, $g, $b
    }
}

function Initialize-WindowsConsoleNativeMethods {
    [CmdletBinding()]
    param()

    if ('TerminalBackground.NativeConsole' -as [type]) {
        return
    }

    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

namespace TerminalBackground
{
    public static class NativeConsole
    {
        private const uint GENERIC_READ = 0x80000000;
        private const uint GENERIC_WRITE = 0x40000000;
        private const uint FILE_SHARE_READ = 0x00000001;
        private const uint FILE_SHARE_WRITE = 0x00000002;
        private const uint OPEN_EXISTING = 3;

        private const uint ENABLE_LINE_INPUT = 0x0002;
        private const uint ENABLE_ECHO_INPUT = 0x0004;
        private const uint ENABLE_VIRTUAL_TERMINAL_INPUT = 0x0200;
        private const uint ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;

        private const uint WAIT_OBJECT_0 = 0x00000000;
        private const uint WAIT_TIMEOUT = 0x00000102;

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr CreateFileW(
            string name,
            uint desiredAccess,
            uint shareMode,
            IntPtr securityAttributes,
            uint creationDisposition,
            uint flagsAndAttributes,
            IntPtr templateFile);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool CloseHandle(IntPtr handle);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool GetConsoleMode(IntPtr handle, out uint mode);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool SetConsoleMode(IntPtr handle, uint mode);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool ReadFile(
            IntPtr handle,
            byte[] buffer,
            uint bytesToRead,
            out uint bytesRead,
            IntPtr overlapped);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool WriteFile(
            IntPtr handle,
            byte[] buffer,
            uint bytesToWrite,
            out uint bytesWritten,
            IntPtr overlapped);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern uint WaitForSingleObject(IntPtr handle, uint milliseconds);

        public static string QueryOsc11(int timeoutMilliseconds)
        {
            IntPtr input = CreateFileW(
                "CONIN$",
                GENERIC_READ | GENERIC_WRITE,
                FILE_SHARE_READ | FILE_SHARE_WRITE,
                IntPtr.Zero,
                OPEN_EXISTING,
                0,
                IntPtr.Zero);

            IntPtr output = CreateFileW(
                "CONOUT$",
                GENERIC_READ | GENERIC_WRITE,
                FILE_SHARE_READ | FILE_SHARE_WRITE,
                IntPtr.Zero,
                OPEN_EXISTING,
                0,
                IntPtr.Zero);

            if (input == new IntPtr(-1) || output == new IntPtr(-1))
            {
                if (input != new IntPtr(-1)) CloseHandle(input);
                if (output != new IntPtr(-1)) CloseHandle(output);
                return null;
            }

            uint originalInputMode;
            uint originalOutputMode;
            bool haveInputMode = GetConsoleMode(input, out originalInputMode);
            bool haveOutputMode = GetConsoleMode(output, out originalOutputMode);

            if (!haveInputMode || !haveOutputMode)
            {
                CloseHandle(input);
                CloseHandle(output);
                return null;
            }

            try
            {
                uint inputMode = originalInputMode;
                inputMode &= ~(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT);
                inputMode |= ENABLE_VIRTUAL_TERMINAL_INPUT;

                uint outputMode = originalOutputMode | ENABLE_VIRTUAL_TERMINAL_PROCESSING;

                if (!SetConsoleMode(input, inputMode) || !SetConsoleMode(output, outputMode))
                    return null;

                byte[] query = Encoding.ASCII.GetBytes("\x1b]11;?\x1b\\");
                uint written;
                if (!WriteFile(output, query, (uint)query.Length, out written, IntPtr.Zero) || written != query.Length)
                    return null;

                var result = new List<byte>();
                var buffer = new byte[64];
                var started = Environment.TickCount64;

                while (Environment.TickCount64 - started < timeoutMilliseconds)
                {
                    int remaining = timeoutMilliseconds - (int)(Environment.TickCount64 - started);
                    if (remaining <= 0)
                        break;

                    uint waitResult = WaitForSingleObject(input, (uint)remaining);
                    if (waitResult == WAIT_TIMEOUT)
                        break;
                    if (waitResult != WAIT_OBJECT_0)
                        return null;

                    uint read;
                    if (!ReadFile(input, buffer, (uint)buffer.Length, out read, IntPtr.Zero))
                        return null;

                    for (int i = 0; i < read; ++i)
                    {
                        byte value = buffer[i];
                        result.Add(value);

                        // OSC replies terminate with BEL or ST (ESC backslash).
                        if (value == 0x07 ||
                            (result.Count >= 2 && result[result.Count - 2] == 0x1b && value == 0x5c))
                        {
                            return Encoding.ASCII.GetString(result.ToArray());
                        }
                    }
                }

                return result.Count == 0 ? null : Encoding.ASCII.GetString(result.ToArray());
            }
            finally
            {
                SetConsoleMode(input, originalInputMode);
                SetConsoleMode(output, originalOutputMode);
                CloseHandle(input);
                CloseHandle(output);
            }
        }
    }
}
'@
}

function Get-Osc11BackgroundRgbWindows {
    [CmdletBinding()]
    param(
        [ValidateRange(50, 5000)]
        [int] $TimeoutMilliseconds = 500
    )

    try {
        Initialize-WindowsConsoleNativeMethods
        $response = [TerminalBackground.NativeConsole]::QueryOsc11($TimeoutMilliseconds)
        if ($response) {
            return ConvertFrom-Osc11Response $response
        }
    }
    catch {
        Write-Verbose "OSC 11 Windows query failed: $($_.Exception.Message)"
    }

    return $null
}

function Get-Osc11BackgroundRgbUnix {
    [CmdletBinding()]
    param(
        [ValidateRange(50, 5000)]
        [int] $TimeoutMilliseconds = 500
    )

    if (-not (Test-Path -LiteralPath '/dev/tty')) {
        return $null
    }

    if (-not (Get-Command sh -ErrorAction Ignore) -or
        -not (Get-Command stty -ErrorAction Ignore)) {
        return $null
    }

    $oldStty = $null
    $stream = $null

    try {
        $oldStty = (& sh -c 'stty -g < /dev/tty 2>/dev/null').Trim()
        if (-not $oldStty) {
            return $null
        }

        # VMIN=0/VTIME=1 makes each read return after at most 100 ms. This lets
        # PowerShell enforce the overall timeout without leaving a blocked read.
        & sh -c 'stty -echo -icanon min 0 time 1 < /dev/tty 2>/dev/null'
        if ($LASTEXITCODE -ne 0) {
            return $null
        }

        $stream = [System.IO.File]::Open(
            '/dev/tty',
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::ReadWrite,
            [System.IO.FileShare]::ReadWrite
        )

        $query = [System.Text.Encoding]::ASCII.GetBytes("$([char]27)]11;?$([char]27)\")
        $stream.Write($query, 0, $query.Length)
        $stream.Flush()

        $bytes = [System.Collections.Generic.List[byte]]::new()
        $buffer = [byte[]]::new(64)
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        while ($stopwatch.ElapsedMilliseconds -lt $TimeoutMilliseconds) {
            $count = $stream.Read($buffer, 0, $buffer.Length)
            if ($count -eq 0) {
                continue
            }

            for ($i = 0; $i -lt $count; $i++) {
                $value = $buffer[$i]
                $bytes.Add($value)

                if ($value -eq 0x07 -or
                    ($bytes.Count -ge 2 -and
                     $bytes[$bytes.Count - 2] -eq 0x1b -and
                     $value -eq 0x5c)) {
                    $response = [System.Text.Encoding]::ASCII.GetString($bytes.ToArray())
                    return ConvertFrom-Osc11Response $response
                }
            }
        }
    }
    catch {
        Write-Verbose "OSC 11 Unix query failed: $($_.Exception.Message)"
    }
    finally {
        if ($stream) {
            $stream.Dispose()
        }

        if ($oldStty) {
            # stty -g produces a machine-generated mode string; pass it as an
            # argument rather than interpolating it into shell syntax.
            & stty -F /dev/tty $oldStty 2>$null
            if ($LASTEXITCODE -ne 0) {
                # macOS/BSD stty uses -f instead of GNU stty's -F.
                & stty -f /dev/tty $oldStty 2>$null
                if ($LASTEXITCODE -ne 0) {
                    # Last-resort portable form.
                    & sh -c "stty '$oldStty' < /dev/tty 2>/dev/null"
                }
            }
        }
    }

    return $null
}

function Get-Osc11BackgroundRgb {
    [CmdletBinding()]
    param(
        [ValidateRange(50, 5000)]
        [int] $TimeoutMilliseconds = 500
    )

    if ($IsWindows) {
        return Get-Osc11BackgroundRgbWindows -TimeoutMilliseconds $TimeoutMilliseconds
    }

    if ($IsLinux -or $IsMacOS) {
        return Get-Osc11BackgroundRgbUnix -TimeoutMilliseconds $TimeoutMilliseconds
    }

    return $null
}

function ConvertTo-WslPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $WindowsPath
    )

    if (-not ($IsLinux -and $env:WSL_DISTRO_NAME)) {
        return $null
    }

    $wslpath = Get-Command wslpath -ErrorAction Ignore
    if (-not $wslpath) {
        return $null
    }

    $path = & $wslpath.Source -u $WindowsPath 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $path) {
        return $null
    }

    $path.Trim()
}

function Get-WindowsLocalAppDataPath {
    [CmdletBinding()]
    param()

    if ($IsWindows) {
        return $env:LOCALAPPDATA
    }

    if ($IsLinux -and $env:WSL_DISTRO_NAME) {
        $powershell = Get-Command powershell.exe -ErrorAction Ignore
        if (-not $powershell) {
            return $null
        }

        $windowsPath = & $powershell.Source -NoProfile -NonInteractive -Command `
            '[Console]::Write($env:LOCALAPPDATA)' 2>$null

        if ($LASTEXITCODE -ne 0 -or -not $windowsPath) {
            return $null
        }

        return ConvertTo-WslPath $windowsPath.Trim()
    }

    return $null
}

function Get-WindowsTerminalSettingsCandidates {
    [CmdletBinding()]
    param()

    $localAppData = Get-WindowsLocalAppDataPath
    if (-not $localAppData) {
        return
    }

    $separator = [System.IO.Path]::DirectorySeparatorChar

    $candidateSpecs = @(
        [pscustomobject]@{
            Flavor      = 'Stable'
            PackageName = 'Microsoft.WindowsTerminal'
            Relative    = 'Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json'
        }
        [pscustomobject]@{
            Flavor      = 'Preview'
            PackageName = 'Microsoft.WindowsTerminalPreview'
            Relative    = 'Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json'
        }
        [pscustomobject]@{
            Flavor      = 'Canary'
            PackageName = 'Microsoft.WindowsTerminalCanary'
            Relative    = 'Packages/Microsoft.WindowsTerminalCanary_8wekyb3d8bbwe/LocalState/settings.json'
        }
        [pscustomobject]@{
            Flavor      = 'Unpackaged'
            PackageName = $null
            Relative    = 'Microsoft/Windows Terminal/settings.json'
        }
    )

    foreach ($spec in $candidateSpecs) {
        $relative = $spec.Relative.Replace('/', $separator)
        $path = Join-Path -Path $localAppData -ChildPath $relative

        if (Test-Path -LiteralPath $path) {
            [pscustomobject]@{
                Flavor       = $spec.Flavor
                PackageName  = $spec.PackageName
                SettingsPath = $path
            }
        }
    }
}

function Get-WindowsTerminalDefaultsPath {
    [CmdletBinding()]
    param(
        [string] $PackageName,
        [string] $SettingsPath
    )

    if ($PackageName) {
        if ($IsWindows) {
            try {
                $package = Get-AppxPackage -Name $PackageName -ErrorAction Stop |
                    Sort-Object Version -Descending |
                    Select-Object -First 1

                if ($package.InstallLocation) {
                    $path = Join-Path $package.InstallLocation 'defaults.json'
                    if (Test-Path -LiteralPath $path) {
                        return $path
                    }
                }
            }
            catch {
                Write-Verbose "Could not locate $PackageName defaults.json via Get-AppxPackage: $($_.Exception.Message)"
            }
        }
        elseif ($IsLinux -and $env:WSL_DISTRO_NAME) {
            $powershell = Get-Command powershell.exe -ErrorAction Ignore
            if ($powershell) {
                # PackageName comes from the fixed candidate list above, not user input.
                $command = @"
`$p = Get-AppxPackage -Name '$PackageName' -ErrorAction SilentlyContinue |
    Sort-Object Version -Descending |
    Select-Object -First 1
if (`$p -and `$p.InstallLocation) {
    [Console]::Write((Join-Path `$p.InstallLocation 'defaults.json'))
}
"@
                $windowsPath = & $powershell.Source -NoProfile -NonInteractive -Command $command 2>$null
                if ($LASTEXITCODE -eq 0 -and $windowsPath) {
                    $path = ConvertTo-WslPath $windowsPath.Trim()
                    if ($path -and (Test-Path -LiteralPath $path)) {
                        return $path
                    }
                }
            }
        }
    }

    # For unpackaged builds, defaults.json commonly lives next to wt.exe.
    if ($SettingsPath) {
        $adjacent = Join-Path (Split-Path -Parent $SettingsPath) 'defaults.json'
        if (Test-Path -LiteralPath $adjacent) {
            return $adjacent
        }
    }

    if ($IsWindows) {
        $wt = Get-Command wt.exe -ErrorAction Ignore
        if ($wt) {
            $adjacent = Join-Path (Split-Path -Parent $wt.Source) 'defaults.json'
            if (Test-Path -LiteralPath $adjacent) {
                return $adjacent
            }
        }
    }
    elseif ($IsLinux -and $env:WSL_DISTRO_NAME) {
        $powershell = Get-Command powershell.exe -ErrorAction Ignore
        if ($powershell) {
            $windowsPath = & $powershell.Source -NoProfile -NonInteractive -Command `
                '$w = Get-Command wt.exe -ErrorAction SilentlyContinue; if ($w) { [Console]::Write((Join-Path (Split-Path -Parent $w.Source) ''defaults.json'')) }' 2>$null

            if ($LASTEXITCODE -eq 0 -and $windowsPath) {
                $path = ConvertTo-WslPath $windowsPath.Trim()
                if ($path -and (Test-Path -LiteralPath $path)) {
                    return $path
                }
            }
        }
    }

    return $null
}

function Read-WindowsTerminalJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    try {
        Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Verbose "Could not parse Windows Terminal JSON '$Path': $($_.Exception.Message)"
        return $null
    }
}

function Get-ObjectPropertyValue {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $Object,

        [Parameter(Mandatory)]
        [string] $Name
    )

    if ($null -eq $Object) {
        return $null
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    $property.Value
}

function Get-FirstObjectPropertyValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]] $Objects,

        [Parameter(Mandatory)]
        [string] $Name
    )

    foreach ($object in $Objects) {
        if ($null -eq $object) {
            continue
        }

        $property = $object.PSObject.Properties[$Name]
        if ($null -ne $property -and $null -ne $property.Value) {
            return $property.Value
        }
    }

    return $null
}

function Find-WindowsTerminalProfile {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $Settings,

        [AllowNull()]
        [object] $Defaults,

        [Parameter(Mandatory)]
        [string] $Profile
    )

    $settingsProfiles = @(Get-ObjectPropertyValue (Get-ObjectPropertyValue $Settings 'profiles') 'list')
    $defaultProfiles = @(Get-ObjectPropertyValue (Get-ObjectPropertyValue $Defaults 'profiles') 'list')

    $userProfile = $settingsProfiles |
        Where-Object { $_ -and ($_.guid -eq $Profile -or $_.name -eq $Profile) } |
        Select-Object -First 1

    $defaultProfile = $defaultProfiles |
        Where-Object { $_ -and ($_.guid -eq $Profile -or $_.name -eq $Profile) } |
        Select-Object -First 1

    if (-not $userProfile -and -not $defaultProfile) {
        return $null
    }

    [pscustomobject]@{
        User    = $userProfile
        Default = $defaultProfile
    }
}

function Get-WindowsAppsUseLightTheme {
    [CmdletBinding()]
    param()

    if ($IsWindows) {
        try {
            return [bool](Get-ItemPropertyValue `
                -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' `
                -Name AppsUseLightTheme `
                -ErrorAction Stop)
        }
        catch {
            return $false
        }
    }

    if ($IsLinux -and $env:WSL_DISTRO_NAME) {
        $powershell = Get-Command powershell.exe -ErrorAction Ignore
        if (-not $powershell) {
            return $false
        }

        $value = & $powershell.Source -NoProfile -NonInteractive -Command `
            '$v = Get-ItemPropertyValue -Path ''HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'' -Name AppsUseLightTheme -ErrorAction SilentlyContinue; if ($null -ne $v) { [Console]::Write($v) }' 2>$null

        if ($LASTEXITCODE -ne 0 -or -not $value) {
            return $false
        }

        $value = $value.Trim()
        return ($value -ne '' -and $value -ne '0')
    }

    return $false
}

function Get-WindowsTerminalThemeObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [AllowNull()]
        [object] $Settings,

        [AllowNull()]
        [object] $Defaults
    )

    foreach ($source in @($Settings, $Defaults)) {
        if (-not $source) {
            continue
        }

        $theme = @(Get-ObjectPropertyValue $source 'themes') |
            Where-Object { $_ -and $_.name -eq $Name } |
            Select-Object -First 1

        if ($theme) {
            return $theme
        }
    }

    return $null
}

function Test-WindowsTerminalApplicationThemeIsLight {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $Settings,

        [AllowNull()]
        [object] $Defaults
    )

    $osIsLight = Get-WindowsAppsUseLightTheme
    $theme = Get-FirstObjectPropertyValue -Objects @($Settings, $Defaults) -Name 'theme'

    if ($null -eq $theme) {
        # Modern Windows Terminal's built-in theme behavior ultimately follows
        # its defaults. In the absence of usable metadata, dark is safer for the
        # terminal content than assuming the Windows application theme.
        return $false
    }

    if ($theme -isnot [string]) {
        $theme = if ($osIsLight) {
            Get-ObjectPropertyValue $theme 'light'
        }
        else {
            Get-ObjectPropertyValue $theme 'dark'
        }
    }

    if (-not $theme) {
        return $false
    }

    switch -Regex ($theme.ToString()) {
        '^light$'  { return $true }
        '^dark$'   { return $false }
        '^system$' { return $osIsLight }
    }

    $themeObject = Get-WindowsTerminalThemeObject -Name $theme -Settings $Settings -Defaults $Defaults
    if (-not $themeObject) {
        return $false
    }

    $window = Get-ObjectPropertyValue $themeObject 'window'
    $applicationTheme = Get-ObjectPropertyValue $window 'applicationTheme'
    if (-not $applicationTheme) {
        return $false
    }

    switch -Regex ($applicationTheme.ToString()) {
        '^light$'  { return $true }
        '^dark$'   { return $false }
        '^system$' { return $osIsLight }
        default    { return $false }
    }
}

function Resolve-WindowsTerminalColorSchemeName {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $ColorScheme,

        [AllowNull()]
        [object] $Settings,

        [AllowNull()]
        [object] $Defaults
    )

    if ($null -eq $ColorScheme) {
        return 'Campbell'
    }

    if ($ColorScheme -is [string]) {
        return $ColorScheme
    }

    $isLight = Test-WindowsTerminalApplicationThemeIsLight -Settings $Settings -Defaults $Defaults
    if ($isLight) {
        return Get-ObjectPropertyValue $ColorScheme 'light'
    }

    Get-ObjectPropertyValue $ColorScheme 'dark'
}

function Get-WindowsTerminalColorScheme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [AllowNull()]
        [object] $Settings,

        [AllowNull()]
        [object] $Defaults
    )

    foreach ($source in @($Settings, $Defaults)) {
        if (-not $source) {
            continue
        }

        $scheme = @(Get-ObjectPropertyValue $source 'schemes') |
            Where-Object { $_ -and $_.name -eq $Name } |
            Select-Object -First 1

        if ($scheme) {
            return $scheme
        }
    }

    return $null
}

function Resolve-WindowsTerminalProfileBackgroundRgb {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $ProfileLayers,

        [AllowNull()]
        [object] $Settings,

        [AllowNull()]
        [object] $Defaults
    )

    $settingsProfiles = Get-ObjectPropertyValue $Settings 'profiles'
    $defaultProfiles = Get-ObjectPropertyValue $Defaults 'profiles'

    $layers = @(
        $ProfileLayers.User
        (Get-ObjectPropertyValue $settingsProfiles 'defaults')
        $ProfileLayers.Default
        (Get-ObjectPropertyValue $defaultProfiles 'defaults')
    )

    $background = Get-FirstObjectPropertyValue -Objects $layers -Name 'background'
    if ($background) {
        return ConvertFrom-TerminalHexColor $background
    }

    $colorScheme = Get-FirstObjectPropertyValue -Objects $layers -Name 'colorScheme'
    $schemeName = Resolve-WindowsTerminalColorSchemeName `
        -ColorScheme $colorScheme `
        -Settings $Settings `
        -Defaults $Defaults

    if (-not $schemeName) {
        return $null
    }

    $scheme = Get-WindowsTerminalColorScheme `
        -Name $schemeName `
        -Settings $Settings `
        -Defaults $Defaults

    if (-not $scheme) {
        Write-Verbose "Windows Terminal color scheme '$schemeName' was not found."
        return $null
    }

    $background = Get-ObjectPropertyValue $scheme 'background'
    if (-not $background) {
        return $null
    }

    ConvertFrom-TerminalHexColor $background
}

function Get-WindowsTerminalBackgroundRgb {
    [CmdletBinding()]
    param(
        # GUID or profile name. When omitted, WT_PROFILE_ID is preferred and
        # settings.json/defaults.json defaultProfile is used as a final fallback.
        [string] $Profile,

        # Optional explicit paths are useful when multiple Terminal channels are
        # installed or when testing a configuration off-line.
        [string] $SettingsPath,
        [string] $DefaultsPath
    )

    if (-not ($IsWindows -or ($IsLinux -and $env:WSL_DISTRO_NAME))) {
        return $null
    }

    $explicitProfile = $PSBoundParameters.ContainsKey('Profile')
    $profileToFind = if ($explicitProfile) { $Profile } else { $env:WT_PROFILE_ID }

    if ($SettingsPath) {
        $candidates = @(
            [pscustomobject]@{
                Flavor       = 'Explicit'
                PackageName  = $null
                SettingsPath = $SettingsPath
            }
        )
    }
    else {
        $candidates = @(Get-WindowsTerminalSettingsCandidates)
    }

    foreach ($candidate in $candidates) {
        $settings = Read-WindowsTerminalJson $candidate.SettingsPath
        if (-not $settings) {
            continue
        }

        $candidateDefaultsPath = $DefaultsPath
        if (-not $candidateDefaultsPath) {
            $candidateDefaultsPath = Get-WindowsTerminalDefaultsPath `
                -PackageName $candidate.PackageName `
                -SettingsPath $candidate.SettingsPath
        }

        $defaults = if ($candidateDefaultsPath) {
            Read-WindowsTerminalJson $candidateDefaultsPath
        }
        else {
            $null
        }

        $candidateProfile = $profileToFind
        if (-not $candidateProfile) {
            $candidateProfile = Get-FirstObjectPropertyValue `
                -Objects @($settings, $defaults) `
                -Name 'defaultProfile'
        }

        if (-not $candidateProfile) {
            continue
        }

        $layers = Find-WindowsTerminalProfile `
            -Settings $settings `
            -Defaults $defaults `
            -Profile $candidateProfile

        if (-not $layers) {
            # If WT_PROFILE_ID or an explicit profile was supplied, another
            # installed Terminal channel may own it.
            if ($profileToFind) {
                continue
            }
            return $null
        }

        $rgb = Resolve-WindowsTerminalProfileBackgroundRgb `
            -ProfileLayers $layers `
            -Settings $settings `
            -Defaults $defaults

        if ($rgb) {
            return $rgb
        }

        # A matching profile identifies this configuration. Do not silently
        # fall through to another Terminal installation with different settings.
        return $null
    }

    return $null
}

function Get-TerminalBackgroundRgb {
    [CmdletBinding()]
    param(
        # Used only by the Windows Terminal fallback. GUID and profile name are
        # both accepted, matching Windows Terminal's defaultProfile semantics.
        [string] $Profile,

        [ValidateRange(50, 5000)]
        [int] $OscTimeoutMilliseconds = 500,

        [switch] $SkipOsc11
    )

    if (-not $SkipOsc11) {
        $rgb = Get-Osc11BackgroundRgb -TimeoutMilliseconds $OscTimeoutMilliseconds
        if ($rgb) {
            return $rgb
        }
    }

    # Native macOS/Linux terminals have no Windows Terminal configuration to
    # consult. WSL is Linux from PowerShell's perspective, but may be hosted by
    # Windows Terminal and inherits WT_PROFILE_ID / WT_SESSION.
    if ($IsWindows -or
        ($IsLinux -and $env:WSL_DISTRO_NAME -and ($env:WT_PROFILE_ID -or $env:WT_SESSION))) {

        $arguments = @{}
        if ($PSBoundParameters.ContainsKey('Profile')) {
            $arguments.Profile = $Profile
        }

        return Get-WindowsTerminalBackgroundRgb @arguments
    }

    return $null
}

function Get-CliThemeFromRgb {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Background
    )

    $luminance = (0.2126 * $Background.R) +
        (0.7152 * $Background.G) +
        (0.0722 * $Background.B)

    if ($luminance -lt 128) {
        return 'dark'
    }

    return 'light'
}

function Get-CliTheme {
    [CmdletBinding()]
    param()

    switch ($env:CLITHEME) {
        'dark' { return 'dark' }
        'light' { return 'light' }
    }

    $background = Get-TerminalBackgroundRgb
    if (-not $background) {
        return $null
    }

    Get-CliThemeFromRgb -Background $background
}

Export-ModuleMember -Function Get-TerminalBackgroundRgb, Get-CliTheme
