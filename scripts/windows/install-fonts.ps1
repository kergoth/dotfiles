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

        If (!(Get-ItemProperty -Name $fontName -Path "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue)) {
            Write-Output "Registering font: $fontFile"
            New-ItemProperty -Name $fontName -Path "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $fontFile.Name -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
    catch {
        Write-Output "Error installing font: $fontFile. " $_.exception.message
    }

}

Add-Type -AssemblyName PresentationCore

Write-Output "Adding user fonts to the registry"
$FontsPath = Join-Path -Path ([Environment]::GetFolderPath('LocalApplicationData')) -ChildPath 'Microsoft\Windows\Fonts'
foreach ($FontItem in (Get-ChildItem -Path $FontsPath |
            Where-Object { ($_.Name -like '*.ttf') -or ($_.Name -like '*.otf') })) {
    Install-Font -fontFile $FontItem.FullName
}
