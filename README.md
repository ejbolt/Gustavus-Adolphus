# Linux Mirror Deployment Script

Deployment tool that was spawned after my previous project (https://github.com/ejbolt/LinuxMirrorScripts)

## When creating Linux mirrors, some have certain rules
### Debian and several of its derivatives:
  use ftpsync: an official collection of scripts that allow you to mirror some or all of the Debian archive;
    I have tested it and it also works with Kali and Raspbian, Ubuntu is hit or miss, try to use ftpsync, and if the mirror you're         trying doesn't work, it may not have been made with ftpsync.  ftpsync creates some trace files that are needed if someone uses ftpsync to mirror YOUR mirror.  Just something to note.
    
### CentOS
  Use an rsync script (base script found here: https://wiki.centos.org/HowTos/CreateLocalMirror)

### Ubuntu
  Use ftpsync if possible, but many Ubuntu mirrors don't sync using ftpsync, so the selection is limited.  If you can't find a good mirror that works for you, use an rsync script.  In the case of this tool, use the custom option for creating an Ubuntu mirror.  I plan to tailor the custom script for this case.

#### What this tool does:
---
- creates a user for maintaining the mirrors
- sets up a directory for all distros
- downloads ftpsync if you selected a distro that uses it
- generates configs for both my custom scripts, and for ftpsync
- changes all affected and appropriate directories to belong to the mirror user
- allows the user to change variables such as default mirror directory, mirror user username, and other config variables as appropriate
- officially supports Arch Linux, CentOS, Debian, Kali, Raspbian, and Ubuntu
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

afterwards, you will have directories in the mirror user's home directory named after each selected distro, and if you selected distros that use ftpsync, a directory named 'archvsync', and a 'bin' and 'etc' directory.  Due to how ftpsync looks for its config files, it's easiest to copy the bin and etc folders out of archvsync (the ftpsync git repo name) and into the home folder.

You can run the scripts manually, OR place them in your crontab (ftpsync has an ftpsync-cron wrapper, you should use that).  They should run fine during the first initial sync, but it wouldn't hurt to run them manually, or set your crontab to run accordingly.

All feedback is welcome.  There are bound to be issues.  I am constantly testing them on my own mirror server to find any hiccups.

Notes: URLs will require editing.  Planning to split rsync url entry to the url, and the path afterwards.

