[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Root,

    [string[]]$SourceFolders = @('PortalEmulator\src', 'Sizzle\src'. 'Benchmarks\src'),

    [switch]$IncludePerFile
)

# Auto-detect project root from script location
$scriptDir = Split-Path -Parent $PSCommandPath
if ([System.IO.Path]::GetFileName($scriptDir) -eq 'tools') {
    $scriptDir = Split-Path -Parent $scriptDir
}

$rootPath = if ($Root) { (Resolve-Path -Path $Root).Path } else { $scriptDir }

function Get-LineCount {
    param([string]$Path)

    $reader = [System.IO.File]::OpenText($Path)
    try {
        $lines = 0
        while ($null -ne $reader.ReadLine()) {
            $lines++
        }
        return $lines
    }
    finally {
        $reader.Dispose()
    }
}

function Get-RelativeLabel {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )

    $baseNormalized = [System.IO.Path]::GetFullPath($BasePath).TrimEnd('\', '/')
    $targetNormalized = [System.IO.Path]::GetFullPath($TargetPath)

    if ($targetNormalized.StartsWith($baseNormalized, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = $targetNormalized.Substring($baseNormalized.Length).TrimStart('\', '/')
        if ($relative) { return $relative } else { return '.' }
    }

    return $TargetPath
}

# Resolve and label source folders
$resolvedFolders = @()
$folderLabels = @()
foreach ($folder in $SourceFolders) {
    $candidate = Join-Path -Path $rootPath -ChildPath $folder
    if (Test-Path -Path $candidate) {
        $fullPath = (Resolve-Path -Path $candidate).Path
        $resolvedFolders += $fullPath
        $folderLabels += (Get-RelativeLabel -BasePath $rootPath -TargetPath $fullPath)
    }
}

if (-not $resolvedFolders) {
    Write-Error "No source folders found under $rootPath. Checked: $($SourceFolders -join ', ')"
    exit 1
}

# Count lines per folder
$folderSummaries = @()
$allFiles = @()
for ($i = 0; $i -lt $resolvedFolders.Count; $i++) {
    $folderFiles = Get-ChildItem -Path $resolvedFolders[$i] -Recurse -Filter *.bf -File
    if (-not $folderFiles) { continue }

    $perFile = foreach ($file in $folderFiles) {
        $lineCount = Get-LineCount -Path $file.FullName
        $fileInfo = [PSCustomObject]@{ File = $file.FullName; Lines = $lineCount }
        $allFiles += $fileInfo
        $fileInfo
    }

    $folderSummaries += [PSCustomObject]@{
        Folder = $folderLabels[$i]
        FileCount = $folderFiles.Count
        LineCount = ($perFile | Measure-Object -Property Lines -Sum).Sum
    }
}

if (-not $folderSummaries) {
    Write-Error "No Beef files found in: $($folderLabels -join ', ')"
    exit 1
}

# Optional per-file breakdown
if ($IncludePerFile) {
    Write-Host "`nPer-file breakdown:" -ForegroundColor Cyan
    $allFiles | Sort-Object Lines -Descending | Format-Table -AutoSize
}

# Summary table with totals
$total = [PSCustomObject]@{
    Folder = 'TOTAL'
    FileCount = ($folderSummaries | Measure-Object -Property FileCount -Sum).Sum
    LineCount = ($folderSummaries | Measure-Object -Property LineCount -Sum).Sum
}

$folderSummaries + $total | Format-Table -AutoSize
