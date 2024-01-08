# https://www.alkanesolutions.co.uk/2021/12/06/installing-fonts-with-powershell/
function Install-Font {
    param
    (
        [System.IO.FileInfo]$fontFile
    )

    try {
        $gt = [Windows.Media.GlyphTypeface]::new($fontFile.FullName)
        $family = $gt.Win32FamilyNames['en-us']
        if ($null -eq $family) { $family = $gt.Win32FamilyNames.Values.Item(0) }
        $face = $gt.Win32FaceNames['en-us']
        if ($null -eq $face) { $face = $gt.Win32FaceNames.Values.Item(0) }
        $fontName = ("$family $face").Trim()

        switch ($fontFile.Extension) {
            ".ttf" { $fontName = "$fontName (TrueType)" }
            ".otf" { $fontName = "$fontName (OpenType)" }
        }

        Write-Host "Installing font: $fontFile with font name '$fontName'"

        If (!(Test-Path ("$($env:windir)\Fonts\" + $fontFile.Name))) {
            Write-Host "Copying font: $fontFile"
            Copy-Item -Path $fontFile.FullName -Destination ("$($env:windir)\Fonts\" + $fontFile.Name) -Force
        }
        else { Write-Host "Font already exists: $fontFile" }

        If (!(Get-ItemProperty -Name $fontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue)) {
            Write-Host "Registering font: $fontFile"
            New-ItemProperty -Name $fontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $fontFile.Name -Force -ErrorAction SilentlyContinue | Out-Null
        }
        else { Write-Host "Font already registered: $fontFile" }

        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($oShell) | Out-Null
        Remove-Variable oShell

    }
    catch {
        Write-Host "Error installing font: $fontFile. " $_.exception.message
    }

}


function Uninstall-Font {
    param
    (
        [System.IO.FileInfo]$fontFile
    )

    try {
        $gt = [Windows.Media.GlyphTypeface]::new($fontFile.FullName)
        $family = $gt.Win32FamilyNames['en-us']
        if ($null -eq $family) { $family = $gt.Win32FamilyNames.Values.Item(0) }
        $face = $gt.Win32FaceNames['en-us']
        if ($null -eq $face) { $face = $gt.Win32FaceNames.Values.Item(0) }
        $fontName = ("$family $face").Trim()

        switch ($fontFile.Extension) {
            ".ttf" { $fontName = "$fontName (TrueType)" }
            ".otf" { $fontName = "$fontName (OpenType)" }
        }

        Write-Host "Uninstalling font: $fontFile with font name '$fontName'"

        If (Test-Path ("$($env:windir)\Fonts\" + $fontFile.Name)) {
            Write-Host "Removing font: $fontFile"
            Remove-Item -Path "$($env:windir)\Fonts\$($fontFile.Name)" -Force
        }
        else { Write-Host "Font does not exist: $fontFile" }

        If (Get-ItemProperty -Name $fontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue) {
            Write-Host "Unregistering font: $fontFile"
            Remove-ItemProperty -Name $fontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -Force
        }
        else { Write-Host "Font not registered: $fontFile" }

        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($oShell) | Out-Null
        Remove-Variable oShell

    }
    catch {
        Write-Host "Error uninstalling font: $fontFile. " $_.exception.message
    }
}

$FontsPath = Join-Path -Path ([Environment]::GetFolderPath('LocalApplicationData')) -ChildPath 'Microsoft\Windows\Fonts'
foreach ($FontItem in (Get-ChildItem -Path $FontsPath |
            Where-Object { ($_.Name -like '*.ttf') -or ($_.Name -like '*.otf') })) {
    Install-Font -fontFile $FontItem.FullName
}

