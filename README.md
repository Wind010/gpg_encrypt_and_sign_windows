# Automate GPG Encryption and Signing of a batch of files.

Expected use on Windows OS.

* Generates a GPG/PGP public/private key pair.
* Encrypts and Signs a directory

## Requirements
Requires https://gpg4win.org/download.html

## Usage

Will prompt for password if no existing matching secret/private key with email/name exists.

```powershell
.\gpg_encrypt_and_sign.ps1
```

## Testing

Run `delete_all_key_pairs.ps1` after testing script.