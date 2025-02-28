# Meant for cleanup after testing GPG pair creation.  Careful if you have real GPG key pairs!

# If you know what you're doing and just testing with no real GPG key pairs.
$acknowledge_auto_deletion = $true
$directory_to_encrypt = "$(Get-Location)\FilesToSignAndEncrypt"

# List all public and secret keys
Write-Host "Listing all public keys:"
gpg --list-keys

Write-Host "Listing all secret keys:"
gpg --list-secret-keys

function Remove-GPGKeyPairs {
    param (
        [string]$keyId
    )
    Write-Host "Deleting key: $keyId"

    if ($acknowledge_auto_deletion)
    {
        gpg --delete-secret-key --batch --yes $keyId
        gpg --delete-key --batch --yes $keyId
    }
    else 
    {
        gpg --delete-secret-key --yes $keyId
        gpg --delete-key --yes $keyId
    }
}


#$publicKeys = gpg --list-keys --with-colons | Select-String -Pattern '^pub:' | ForEach-Object { $_.Line.Split(':')[4] }
#$secretKeys = gpg --list-secret-keys --with-colons | Select-String -Pattern '^sec:' | ForEach-Object { $_.Line.Split(':')[4] }

# If we have multiple keys by the same email the keyId won't cut it.
$keyFingerPrints = $(gpg --list-keys --with-fingerprint --with-colon) -split "`n" `
    | Where-Object { $_ -match 'fpr:::::::::' } | ForEach-Object {$_.Split(':')[9]}

#$keyFingerPrints = gpg --list-keys --with-colons | Select-String "fpr"

# Delete each secret key and its corresponding public key
foreach ($keyId in $keyFingerPrints) {
    Remove-GPGKeyPairs -keyId $keyId
}


function Remove-GenerateFiles()
{
    Remove-Item -Path $directory_to_encrypt\*.sig
    Remove-Item -Path $directory_to_encrypt\*.gpg
    Remove-Item -Path "$(Get-Location)\PublicKeys\public_key.asc" -ErrorAction SilentlyContinue
}

Remove-GenerateFiles


Write-Host "✅ All public and private/secret GPG keys have been deleted." -ForegroundColor Green
