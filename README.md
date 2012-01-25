# General description

`pwdmgr` is a small and simple password manager utility.

Typical use is through *dmenu* (<http://tools.suckless.org/dmenu/>)

An *administration console* is also provided.

## Features:

 - enter a pass key, the actual password is copied in X clipboard
 - vault encrypted via openssl (Blowfish Cipher) using a master key
 - vault merge
 - vault up/download

## Dependencies:

 - **xclip** (mandatory)
 - **openssl** (mandatory)
 - either **curl** or **scp** (optional, but useful if you want to
   keep your vault in the cloud)
 - **dmenu** (optional, but useful if you don't want to use the
     console for nominal use case)
 - **xterm** (optional, but useful to let the console open itself in
     graphical environments)

## Typical use

 - bind `<super>k` to *pwdmgr_menu*
 - bind `<super><shift>k` to *pwdmgr_console*

# Configuration

The configuration file is usually found in your home directory:
`$HOME/.pwdmgr/config.rc`

A system-wide configuration file may be found at `/etc/pwdmgr.rc`.

Some sample files are available in the documentation section of your
package (the default install places those files in
`/usr/local/share/doc/pwdmgr/`). Look at the `sample-*.rc` files.

THose files are auto-documented. Just open them and read the comments
to find how to modify them.

# Features details

## Password management

Passwords are kept in a single file, known as the *vault*. This file
is encrypted by a "master pass phrase". It is the only pass you'll
need to know!

The passwords are referenced by a unique key. They are never displayed
in clear text.

## The server

The server is responsible for keeping the vault open using a pass
phrase you'll need to type only once.

To close the vault, just type `stop` in the administration console
(see below). It will stop the server.

## The menu

The menu is a very quick and efficient way of getting a password. Just
enter the key of the password you need; the password is made available
in the X clipboard, just type `ctrl-C` or click the middle button of
your mouse to paste it in a password form.

The most typical use is all the web login sites (google, facebook,
banks...) Never have duplicate passwords anymore!

## The administration console

The administration console allows more operations on the vault. The
most useful is ceraintly the `add` command, that will add a new vault
entry using the provided key.

For instance, `add foo` will generate a unique random password and
store it in the vault using the key *foo*. The password is also made
available to the X clipboard for pasting in the form of the new
account you are just creating `:-)`

Another usage is `add foo prompt`. In that case, the password is not
generated, but you will need to enter it in the dialog that pops
up. The password is then stored in the vault and also made available
in the X clipboard. This usage is not recommended except for
already-known passwords (to fill up your vault), or for sites that
have ugly (and usually weak) password policies.

For other commands, just type `help`.

## Remoting and merging

OK, now you have a vault at home in your desktop, another on your
laptop, a third one at work. How do you merge them?

First, you must define a *central location* where your vault is to be
kept. Preferably a cloud space you own.

Fill in the corresponding fields in the configuration file.

When those fields are correctly set, the administration console
provides a few useful commands:

 - `save` saves your local vault up to the cloud
 - `load` loads the vault from the cloud (it overwrites your local one!)
 - `merge` attempts to merge both the local cloud and the one in the
   vault, saving the result back up to the cloud.

Let's focus on that last operation, which should be the most
common. The merge should work as expected. Added keys are added,
removed keys are removed.

The only difficult case arise if a key is updated in both vaults. In
that case, the one with the greatest number of changes wins; if equal,
then the local version wins.

Note that, to help merge take decisions in the latter case, keys are
never really deleted from the vault. They are simply marked as being
removed.
