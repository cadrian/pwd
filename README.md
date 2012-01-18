pwdmgr is a small and simple password manager utility.

Typical use is through *dmenu* (<http://tools.suckless.org/dmenu/>)

An *administration console* is also provided.

## Features:

 - enter a pass key, the actual password is copied in X clipboard
 - vault encrypted via openssl (Blowfish Cipher) using a master key
 - vault merge
 - vault up/download

## Dependencies:

 - xclip (mandatory)
 - openssl (mandatory)
 - curl (optional, but useful if you want to keep your vault in the cloud)
 - dmenu (optional, but useful if you don't want to use the console for nominal use case)
