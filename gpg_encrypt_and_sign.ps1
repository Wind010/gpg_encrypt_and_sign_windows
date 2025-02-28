# # Ensure GPG is installed... might be overkill
# if (-not (Get-Command "gpg" -ErrorAction SilentlyContinue)) {
#     Write-Output "gpg not found. Installing via Chocolatey..."
#     if (-not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
#         Write-Output "Chocolatey is required but not found. Install it first: https://chocolatey.org/install"
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

################ END:  Ok to edit ################





######################## DO not edit below unless you really want toN...  ################################

if ([string]::IsNullOrWhiteSpace($directory_to_encrypt))
{
    $directory_to_encrypt = Read-Host "Enter the path to the folder containing files to encrypt"
}

# Check if key already exists
$key_exists = gpg --list-keys "$email" 2>$null
if (-not $key_exists) {
    Write-Output "No gpg key found for $email. Generating a new key..."

    # Prompt user for passphrase securely
    $secure_passphrase = Read-Host "Enter a secure passphrase for the gpg key" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure_passphrase)
    $passphrase = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

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
    Write-Output "gpg key pair generated successfully."
} else {
    Write-Output "gpg key for $email already exists."
}

 
if (-not (Test-Path $directory_to_encrypt -PathType Container)) {
    Write-Output "Invalid folder path. Exiting."
    exit 1
}

# Process all files in the specified folder
$files = Get-ChildItem -Path $directory_to_encrypt -File
foreach ($file in $files) {
    $file_path = $file.FullName
    $encrypted_file = "$($file.FullName).gpg"
    $signed_file = "$($file.FullName).sig.gpg"

    Write-Output "Encrypting $file_path..."
    gpg --encrypt --recipient "$email" --output "$encrypted_file" "$file_path"
    Write-Output "File encrypted: $encrypted_file"

    Write-Output "Signing $encrypted_file..."
    gpg --sign --local-user "$email" --output "$signed_file" "$encrypted_file"
    Write-Output "File signed: $signed_file"
}

Write-Output "✅ Encryption and signing complete for all files in: $directory_to_encrypt"
Write-Output "Encryption and signing complete! 🚀"


