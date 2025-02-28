$ErrorActionPreference = "Stop" # 💀


# # Ensure GPG is installed... might be overkill
# if (-not (Get-Command "gpg" -ErrorAction SilentlyContinue)) {
#     Write-Host "gpg not found. Installing via Chocolatey..."
#     if (-not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
#         Write-Host "Chocolatey is required but not found. Install it first: https://chocolatey.org/install"
#         exit 1
#     }
#     choco install gnupg -y
#     $env:path += ";C:\Program Files (x86)\GnuPG\bin"
# }


################ START:  Ok to edit ################

# Define key details
$name = "Test McTestFace"
$email = "test.mctestface@someplace.htb"
$key_type = "RSA"
$key_length = 4096
$expire = "1y"

$directory_to_encrypt = "$(Get-Location)\FilesToSignAndEncrypt"
$public_key_directory = "$(Get-Location)\PublicKeys"  # Location where you want to export the public key to.
$public_key_filename = "public_key.asc"  # Name of public key.  Update as needed.

################ END:  Ok to edit ################





######################## DO not edit below unless you really want toN...  ################################

if ([string]::IsNullOrWhiteSpace($directory_to_encrypt))
{
    $directory_to_encrypt = Read-Host "Enter the path to the folder containing files to encrypt"
}

# Check if key already exists
$key_exists = gpg --list-keys "$email" 2>$null
if (-not $key_exists) {
    Write-Host "No gpg key found for $email. Generating a new key..."

    # Prompt user for passphrase securely.  Had issues without using 
    $secure_passphrase = Read-Host "Enter a secure passphrase for the gpg key" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure_passphrase)
    $passphrase = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) # Free the string from memory.

    # Temporary file for key configuration
    $temp_key_file = New-TemporaryFile
    @"
    %echo Generating a standard key
    Key-Type: $key_type
    Key-Length: $key_length
    Name-Real: $name
    Name-Email: $email
    Expire-Date: $expire
    Passphrase: $passphrase
    %commit
"@ | Set-Content $temp_key_file

    # Generate the key pair
    gpg --batch --gen-key $temp_key_file
    Remove-Item $temp_key_file -Force
    Write-Host "✅ gpg key pair generated successfully." -ForegroundColor Green
} else {
    Write-Host "gpg key for $email already exists." 
}

 
if (-not (Test-Path $directory_to_encrypt -PathType Container)) {
    Write-Host "❌ Invalid folder path. Exiting." -ForegroundColor Red
    exit 1
}

# Process all files in the specified folder
Write-Host "`nEncrypting and signing files in: $directory_to_encrypt..." -ForegroundColor Blue
$files = Get-ChildItem -Path $directory_to_encrypt -File
foreach ($file in $files) {
    $file_path = $file.FullName
    $encrypted_file = "$($file.FullName).gpg"
    $signed_file = "$($file.FullName).sig.gpg"

    Write-Host "`t🔒 Encrypting $file_path..." -ForegroundColor Blue
    gpg --encrypt --recipient "$email" --output "$encrypted_file" "$file_path"
    Write-Host "`t🚀 File encrypted: $encrypted_file" -ForegroundColor Green

    Write-Host "`t✍️ Signing $encrypted_file..." -ForegroundColor Blue
    gpg --sign --batch --local-user "$email" --output "$signed_file" "$encrypted_file"
    Write-Host "`t🚀 File signed: $signed_file" -ForegroundColor Green
}


Write-Host "`n✅ Encryption and signing complete for all files in: $directory_to_encrypt" -ForegroundColor Green

$key_list = gpg --list-keys --with-colons | Select-String "fpr"
$key_count = ($key_list | Measure-Object).Count
if ($key_count -eq 1) {
    $fingerprint = ($key_list -split ":")[9]  # Extract the fingerprint automatically
} else {
    # Prompt user to choose a fingerprint if multiple keys found.
    Write-Host "Multiple GPG keys found. Please choose the fingerprint to export:"
    $key_list | ForEach-Object { Write-Host $_ }
    gpg --list-keys
    $fingerprint = Read-Host "Enter the fingerprint of the key to export"
}

Write-Host "`nExporting the public key for $email and $fingerprint..." -ForegroundColor Blue
$public_key_path = "$public_key_directory\$public_key_filename"
gpg --export --armor "$fingerprint" > $public_key_path
Write-Host "✅ Public key exported to: $public_key_path" -ForegroundColor Green

Write-Host "`n✅ Total Process completed! 🚀" -ForegroundColor Green


