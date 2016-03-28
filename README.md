my-shell
======

my-shell project contains my shell environment settings like aliases and small scripts. They should be compatible with both linux and OSX. If not, please open an issue.

## Installation

##### Shell Settings

Issue the commands below in terminal to install. This one-liner will download `install_shell_settings.sh` and run it in your sh environment. Also, you can download installer and run it on your own machine but this is easiest way.

```sh
curl -sL https://git.io/vVftO | bash
```
The command above downloads `alias.sh` and `bash.sh` files to your home folder as hidden files and source them in your profile file. If you want to install them for all users in the machine, you must copy these files to `/etc` and source them in your main system wide profile file.

To uninstall, delete the files `.myaliases.sh` and `.bash.sh` files in your home directory and remove the relevant lines in your profile file.

##### Scripts

To use scripts in `scripts`folder, simply run the command below or download and copy them to `/usr/local/bin`. You should run the command with `sudo` because of `/usr/local/bin`. 

```sh
curl -sL https://git.io/vVfYB | sudo bash
```
