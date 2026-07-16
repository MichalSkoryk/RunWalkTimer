[CmdletBinding()]
param(
    [string]$DeviceId,
    [switch]$SkipChecks
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw @"
Flutter is not on PATH.
Install the stable Flutter SDK, add its bin folder to PATH, open a new
PowerShell window, and run 'flutter doctor'. See README.md for the full setup.
"@
}

Push-Location $projectRoot
try {
    if (-not $SkipChecks) {
        & flutter pub get
        if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed." }

        & flutter analyze
        if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed." }

        & flutter test
        if ($LASTEXITCODE -ne 0) { throw "flutter test failed." }
    }

    $deviceJson = & flutter devices --machine
    if ($LASTEXITCODE -ne 0) { throw "Unable to list Flutter devices." }

    $androidDevices = @(
        $deviceJson |
            ConvertFrom-Json |
            Where-Object { $_.targetPlatform -like "android-*" }
    )

    if ([string]::IsNullOrWhiteSpace($DeviceId)) {
        if ($androidDevices.Count -eq 0) {
            throw @"
No Android device was found.
Connect a data-capable USB cable, enable USB debugging, accept the phone's
authorization prompt, and verify the connection with 'flutter devices'.
"@
        }

        if ($androidDevices.Count -gt 1) {
            Write-Host "More than one Android target is available:"
            $androidDevices |
                ForEach-Object { Write-Host "  $($_.id)  $($_.name)" }
            throw "Run this script again with -DeviceId '<device-id>'."
        }

        $DeviceId = $androidDevices[0].id
    }

    Write-Host "Launching Run/Walk Timer on $DeviceId..."
    & flutter run -d $DeviceId
    if ($LASTEXITCODE -ne 0) { throw "flutter run failed." }
}
finally {
    Pop-Location
}
