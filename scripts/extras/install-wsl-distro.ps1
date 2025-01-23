## After reboot to enable the WSL features
try {
  # Features don't work inside a Sandbox
  Get-WindowsOptionalFeature -Online -ErrorAction SilentlyContinue
  if (-not $error) {
    $wsl = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    if ($wsl) {
      # Update WSL kernel
      $kernel = $env:TEMP + '/kernel.msi'
      try {
        Invoke-WebRequest https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi -OutFile $kernel -UseBasicParsing
        Add-AppxPackage $kernel
      }
      finally {
        Remove-Item $kernel
      }

      # Install Arch
      scoop install archwsl
      # Arch is updated through pacman
      scoop hold archwsl
    }

    $wsl2 = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    if ($wsl2) {
      # Use WSL 2 by default
      wsl --set-default-version 2

      # Use WSL 2 for Arch
      wsl --set-version Arch 2

      # Install pwsh
      winget install pwsh --silent

      # Fix WSL 2 + VPN
      $hypervfix = $env:TEMP + '/hypervfix.zip'
      try {
        Invoke-WebRequest https://github.com/jgregmac/hyperv-fix-for-devs/archive/refs/heads/master.zip -OutFile $hypervfix -UseBasicParsing

        $hypervdir = $env:TEMP + '/hyperv-fix-for-devs'
        try {
          Expand-Archive $hypervfix -DestinationPath $hypervdir -Force
          Get-ChildItem $hypervdir -Include *.ps1,*.psm1 -Recurse | Unblock-File -Confirm:$false
          C:\Program Files\PowerShell\7\pwsh.exe -File $hypervdir\hyperv-fix-for-devs-master\Install-DeveloperFix.ps1
        }
        finally {
          Remove-Item -Recurse $hypervdir
        }
      }
      finally {
        Remove-Item $hypervfix
      }
    }
  }
}
catch {
}

