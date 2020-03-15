# Gustavus Adolphus
In the early 1600s, Gustav II Adolph of Sweden reformed the administrative structure of Sweden and his military innovation allowed Sweden to become a great power for the next 70 years.  For these accomplishments, as well as those on the battlefield, he's been called The Lion of the North.

## Linux Mirror Deployment Tool

Deployment tool that was spawned after my previous project (https://github.com/ejbolt/LinuxMirrorScripts)

## When creating Linux mirrors, some have certain rules

### Arch Linux
  Use an rsync script (https://wiki.archlinux.org/index.php/DeveloperWiki:NewMirrors#2-tier_mirroring_scheme)

### CentOS
  Use an rsync script (base script found here: https://wiki.centos.org/HowTos/CreateLocalMirror)

### Debian and several of its derivatives:
  use ftpsync: an official collection of scripts that allow you to mirror some or all of the Debian archive;
    I have tested it and it also works with Kali and Raspbian, Ubuntu is hit or miss, try to use ftpsync, and if the mirror you're         trying doesn't work, it may not have been made with ftpsync.  ftpsync creates some trace files that are needed if someone uses ftpsync to mirror YOUR mirror.  Just something to note.
    
### Fedora
  Use fedora-quick-mirror, a ZSH script that optimizes how rsync retrieves files for a Fedora mirror.  Requires some configuration, and intend to add a script that generates the config for that file.
  
### Ubuntu
  Use ftpsync if possible, but many Ubuntu mirrors don't sync using ftpsync, so the selection is limited.  If you can't find a good mirror that works for you, use an rsync script.  In the case of this tool, use the custom option for creating an Ubuntu mirror.  I plan to tailor the custom script for this case.
  
### Various
  Most \*nix distros utilize rsync and a web server and that's that.  These also include Free/Net/OpenBSD, as well as OpenSUSE, Qubes, Slackware, and Void Linux 

#### What this tool does:
---
- creates a user for maintaining the mirrors
- sets up a directory for all distros
- downloads ftpsync if you selected a distro that uses it
- generates configs for both my custom scripts, and for ftpsync
- changes all affected and appropriate directories to belong to the mirror user
- allows the user to change variables such as default mirror directory, mirror user username, and other config variables as appropriate
- officially supports Arch Linux, CentOS, Debian, FreeBSD, Kali, Linux Mint, Manjaro, NetBSD, OpenBSD, Qubes, Raspbian, TinyCoreLinux,  Ubuntu, and Void Linux
--- 
#### What this tool does NOT do, but plan for it to:
---
- Install needed dependencies for whatever distro it is running on ( such as apache, I don't plan for
  this tool to create an rsync mirror, but all that would require is pointing your rsync server at the
  mirror's root directory.
- allow for advanced variable customization for ftpsync-related distros
- support Fedora (requires I read into their mirroring tool, that's on the current todo list)
- detect when running as root and change any sudo commands as appropriate
---
BEFORE USING THIS TOOL YOU SHOULD LOOK INTO HOW FTPSYNC WORKS AND AT MY CUSTOM SCRIPTS  
You can look at the 'generic.sh' script in my other repo listed above.  It's the template for the custom scripts.

ftpsync requires that you choose which architectures to mirror, look into what architectures you want, and pick an appropriate rsync mirror to sync from that supports all of the desired architectures.

All you need to do is git clone this repo, and run the script as a user with sudo priviledges

Afterwards, you will have directories in the mirror user's home directory named after each selected distro, and if you selected distros that use ftpsync, a directory named 'archvsync', and a 'bin' and 'etc' directory.  Due to how ftpsync looks for its config files, it's easiest to copy the bin and etc folders out of archvsync (the ftpsync git repo name) and into the home folder.

You can run the scripts manually, OR place them in your crontab (ftpsync has an ftpsync-cron wrapper, you should use that).  They should run fine during the first initial sync, but it wouldn't hurt to run them manually, or set your crontab to run accordingly.  I suggest to use `flock` or whichever file-locking program is on your host distro, i.e.:
`/usr/bin/flock -w 0 /tmp/archlinux.lock /bin/bash archlinux-rsync.sh`
This is especially important for large distros that are subject to large updates and you are syncing by running these scripts in your crontab.

All feedback is welcome.  There are bound to be issues.  I am constantly testing them on my own mirror server to find any hiccups.

Notes: Read the script code to see how it wants the rsync URL.  I'd like to be able to smartly append the distro name to the URL, but since the directory path of Linux mirrors is not ubiquitous, that's a little tricky, so meh.

