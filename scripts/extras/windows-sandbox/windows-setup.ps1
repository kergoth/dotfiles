Set-Location c:\system-setup

.\setup-admin.ps1
runas /trustlevel:0x20000 "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -Verbose -NoExit -WindowStyle Maximized -NoProfile -InputFormat None -ExecutionPolicy RemoteSigned -File .\setup.ps1"
