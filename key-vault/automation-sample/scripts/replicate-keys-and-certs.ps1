param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$SourceVaultName,

    [Parameter(Mandatory = $true)]
    [string]$TargetVaultName,

    [string]$TempPath = ".\\tmp-kv-replication",

    [switch]$SkipKeys,

    [switch]$SkipCertificates
)

$ErrorActionPreference = "Stop"

az account set --subscription $SubscriptionId

New-Item -Path $TempPath -ItemType Directory -Force | Out-Null

try {
    if (-not $SkipKeys) {
        $keys = az keyvault key list --vault-name $SourceVaultName --query "[].name" -o tsv
        foreach ($keyName in $keys) {
            if ([string]::IsNullOrWhiteSpace($keyName)) { continue }
            $file = Join-Path $TempPath "$keyName.keybackup"
            az keyvault key backup --vault-name $SourceVaultName --name $keyName --file $file | Out-Null
            az keyvault key restore --vault-name $TargetVaultName --file $file | Out-Null
            Write-Host "Replicated key: $keyName"
        }
    }

    if (-not $SkipCertificates) {
        $certs = az keyvault certificate list --vault-name $SourceVaultName --query "[].name" -o tsv
        foreach ($certName in $certs) {
            if ([string]::IsNullOrWhiteSpace($certName)) { continue }
            $file = Join-Path $TempPath "$certName.certbackup"
            az keyvault certificate backup --vault-name $SourceVaultName --name $certName --file $file | Out-Null
            az keyvault certificate restore --vault-name $TargetVaultName --file $file | Out-Null
            Write-Host "Replicated certificate: $certName"
        }
    }
}
finally {
    if (Test-Path $TempPath) {
        Remove-Item -Path $TempPath -Recurse -Force
    }
}

Write-Host "Key and certificate replication completed."
