# Linux Mirror Deployment Script

Deployment tool that was spawned after my previous project (https://github.com/ejbolt/LinuxMirrorScripts)

## When creating Linux mirrors, some have certain rules
### Debian and several of its derivatives:
  use ftpsync: an official collection of scripts that allow you to mirror some or all of the Debian archive;
    I have tested it and it also works with Kali and Raspbian, however I haven't found any Ubuntu mirrors that it works with
    
### CentOS
  use an rsync script (base script found here: https://wiki.centos.org/HowTos/CreateLocalMirror)

### Ubuntu
  use an rsync script (base script found here: https://wiki.ubuntu.com/Mirrors/Scripts)
  
After writing my previous scripts, there were a lot of similaries seen in the rsync commands between CentOS and Ubuntu, and many defaults in ftpsync that worked very well when added to my custom scripts.

So I decided to write a dialog menu script that would automate deploying the mentioned Linux distros.

#### What this tool does:
---
- creates a user for maintaining the mirrors
- sets up a directory for all distros
- downloads ftpsync if you selected a distro that uses it
- generates configs for both my custom scripts, and for ftpsync
- changes all affected and appropriate directories to belong to the mirror user
- allows the user to change variables such as default mirror directory, mirror user username, and other config variables as appropriate
--- 
#### What this tool does NOT do, but plan for it to:
---
- Install needed dependencies for whatever distro it is running on
- allow for advanced variable customization for ftpsync-related distros
- support Fedora (requires I read into their mirroring tool, that's on the current todo list
- detect when running as root and change any sudo commands as appropriate
---
BEFORE USING THIS TOOL YOU SHOULD LOOK INTO HOW FTPSYNC WORKS AND AT MY CUSTOM SCRIPTS  
You can look at the 'generic.sh' script in my other repo listed above.  It's the template for the custom scripts.

ftpsync requires that you choose which architectures to mirror, look into what architectures you want, and pick an appropriate rsync mirror to sync from that supports all of the desired architectures.

All you need to do is git clone this repo, and run the script as a user with sudo priviledges

afterwards, you will have directories in the mirror user's home directory named after each selected distro, and if you selected distros that use ftpsync, a directory named 'archvsync', and a 'bin' and 'etc' directory.  Due to how ftpsync looks for its config files, it's easiest to copy the bin and etc folders out of archvsync (the ftpsync git repo name) and into the home folder.

You can run the scripts manually, OR place them in your crontab (ftpsync has an ftpsync-cron wrapper, you should use that).  They should run fine during the first initial sync, but it wouldn't hurt to run them manually, or set your crontab to run accordingly.

All feedback is welcome.  There are bound to be issues.  I am constantly testing them on my own mirror server to find any hiccups.