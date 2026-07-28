param(
    [Parameter(Mandatory = $true)]
    [string]$FunctionAppName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup
)

$ErrorActionPreference = "Stop"

Push-Location ..
try {
    Write-Host "Publishing Function App package..."
    func azure functionapp publish $FunctionAppName --python --build remote
}
finally {
    Pop-Location
}

Write-Host "Publish completed."
