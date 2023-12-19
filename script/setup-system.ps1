if ($IsWindows) {
    # Get the ID and security principal of the current system account
    $myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

    # Get the security principal for the Administrator role
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

    # Check to see if we are currently running "as Administrator"
    if (-Not $myWindowsPrincipal.IsInRole($adminRole)) {
        # We are not running "as Administrator" - so relaunch as administrator

        # Create a new process object that starts PowerShell
        $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";

        # Specify the current script path and name as a parameter
        $newProcess.Arguments = $myInvocation.MyCommand.Definition;

        # Indicate that the process should be elevated
        $newProcess.Verb = "runas";

        # Start the new process
        [System.Diagnostics.Process]::Start($newProcess);

        # Exit from the current, unelevated, process
        exit
    }
}

. $PSScriptRoot\..\scripts\common.ps1

$os = $null
if ($IsLinux) {
    $os = "linux"
}
elseif ($IsMacOS) {
    $os = "macos"
}
elseif ($IsWindows) {
    $os = "windows"
}
if ($os) {
    $script = Join-Path $PSScriptRoot ".." "scripts" "setup-system-$os.ps1"
    if (Test-Path $script) {
        Write-Output "Running setup-system-$os.ps1"
        $script | Invoke-Expression
    }
    else {
        Write-Error "No setup-system-$os.ps1 script found"
    }
}
if ($IsLinux) {
    if (Test-Path "/etc/os-release") {
        $release = Get-Content /etc/os-release | ConvertFrom-StringData
        $distro = $release.ID
        $script = Join-Path $PSScriptRoot ".." "scripts" "setup-system-$distro.ps1"
        if (Test-Path $script) {
            Write-Output "Running setup-system-$distro.ps1"
            $script | Invoke-Expression
        }
        else {
            Write-Warning "No setup-system-$distro.ps1 script found"
        }
    }
}

Write-Output "System setup complete"
