mybash
======

This shell scripts contains my personalized bash settings for inst; *aliases*, *small functions* etc.. I tried my best to make it compatible for both Linux and Mac OS X. If you have an issue, please open an issue.

## Installation

##### Installing only for yourself

To install, issue the commands below in terminal. This procedure creates a hidden directory named `~/.mybash/` and copies `bash_aliases.bashrc` and `mybash.bashrc` files into it. Also, adds a line into `~/.bashrc` sourcing the `mybash.bashrc` file.
```sh
git clone https://github.com/isezen/mybash.git
./install.sh
. ~/.bashrc
```

##### Install for all users

To install for *all users* (**requires root privileges**), issue the commands below in terminal. This procedure creates a directory named `/etc/mybash/` and copies `bash_aliases.bashrc` and `mybash.bashrc` files into it. Also, adds a line into `/etc/bash.bashrc` for Linux (`/etc/bashrc` for MAC OS X) sourcing the `/etc/mybash/mybash.bashrc` file.` 
```sh
git clone https://github.com/isezen/mybash.git
./install.sh -a
```
#### Uninstall:
If you installed before for the current user, you can use the commands below as it is.
```sh
./install.sh -u
. ~/.bashrc
```
If you installed before for *all users*, use `-a` flag to uninstall for *all users*. **(Requires root privileges)**
```sh
./install.sh -ua
. ~/.bashrc
```

