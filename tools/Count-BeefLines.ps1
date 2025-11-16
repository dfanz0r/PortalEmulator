[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Root = (Get-Location).Path,

    [switch]$IncludePerFile
)

$rootPath = Resolve-Path -Path $Root
$srcPath = Join-Path -Path $rootPath -ChildPath 'src'

if (-not (Test-Path -Path $srcPath)) {
    Write-Error "Could not find 'src' under $rootPath"
    exit 1
}

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

$files = Get-ChildItem -Path $srcPath -Recurse -Filter *.bf -File
if (-not $files) {
    Write-Error "No Beef files were found under '$srcPath'."
    exit 1
}

$perFile = foreach ($file in $files) {
    $lineTotal = Get-LineCount -Path $file.FullName
    [PSCustomObject]@{ File = $file.FullName; Lines = $lineTotal }
}

if ($IncludePerFile) {
    Write-Host "Files under 'src':" -ForegroundColor Cyan
    $perFile | Sort-Object Lines -Descending | Format-Table -AutoSize
    Write-Host ''
}

$summary = [PSCustomObject]@{
    Scope = 'src'
    FileCount = $files.Count
    LineCount = ($perFile | Measure-Object -Property Lines -Sum).Sum
}

$summary | Format-Table -AutoSize
