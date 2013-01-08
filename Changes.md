Add virtualenv burrito for Python

v1.8.4
------
Add rbenv integration and safeties for rvm
Remove the rvm post-cd hooks (they suck anyway)
YET MORE fixes to PATH construction
Make RVM integration a little less noisy
ls -o on OSX should have been ls -O

v1.8.3
------
Better RVM integration
More tweaks to PATH handling (again!)
Add Mojo Lingo network
Put Git and RVM on the PS1

v1.8.2
------
Print the current Git branch
Print the current RVM version
Preserve directory breadcrumbs with RVM
Automatically load RVM if available

v1.8.1
------
Add bash_completion, improve nscheck (still needs more...)
Improve detection of GNU grep on (Open)Solaris
Add function to check Alkaloid nameserver for updates
Replace all "echo -e" references with "printf" (again)
Make sure the user's preferred PATH is in front of the system PATH

v1.8.0
------
Fix ls location bug (type -P)

v1.7.9
------
Update alkaloid network color
Fix ls location and argument determination
Try to find GNU utilities before checking capabilities
Allow control characters in 'less' output to display terminal colors
Set screen window titles like Konsole/iTerm tab names
Smart case-insensitive searches in less(1)
Colorize grep(1) output by default
Allow control characters in less(1) output to display terminal colors
Add arg "-o" to ls alias on OSX to show flags on files when using -l
Make top(1) sort by CPU on OS X

v1.7.8
------
Exit immediately if not an interactive shell.  Fixes a KDM login bug in Kubuntu 8.04 Hardy.
Add System Efficiency (syseff) network color
Fix echo -n (should be printf); Formatting tweak on upgrade message

v1.7.7
------
How's about we actually *export* $BASHRC so it can propagate, hmmm?
Fix broken return code handling (thanks Jeff, Bryan)
Add schmod (similar to sls)

v1.7.6
------
Reorganize and label sections to keep similar settings together
Optimize PS1 to use $EUID rather than `id -u`
Only print the Konsole control chars if $TERM is an xterm
Append '#' to the tab name when root
Make the PATH and umask the very first thing configured
Add newline to hostname/OS login announcement
Add sls function for Nexenta to get at ZFS ACLs easily
Add Horde and Nexenta network colors
Add getent wrapper for HP-UX
Add Sunrise network color
Re-order the escape sequences so titlebar is set after tab name

v1.7.5
------
vi mode must come *before* any key bindings
Auto-set tab name in Konsole
Add _logout() function
Auto-create .bash_logout to run _logout
Add check for host-specific logout script
Add notes about setting Konsole tab color
Set Konsole tab color to red when root
Do not attempt to propagate .bashrc if unable to encode file
Mute warnings about missing B64 encoder on shell startup
Cygwin has titlebar setting functionality

v1.7.4
------
Cygwin now supported
Support ${HOME}s that have a space in the path
Reorder sections for usability
Check for ":$" in PATH (same as :.)
Whitespace, comments

v1.7.3
------
Add missing 1.7.3 version tag and alkaloiddev network
Rev 420: This one goes out to Bryan
Mute perl warnings (deja-vu?)
Reset term color after printing PATH warning
Allow for local per-host environment override ~/.localenv-$HOSTNAME.sh
Added security check for "." in $PATH
Allow $HOME/.PATH to precede /etc/PATH
Replace /tmp with $TMPDIR, check and set $TMPDIR
Modified `lkp` to flag current principal
Symlink current TGT to default location

v1.7.2
------
Added Kerberos TGT management (akp/lkp/ckp/dkp)
Added LANG=C to environment
Added cmsc colors
Updated voffice colors

v1.7.1
------
Added keybinding ^E to FCEDIT

v1.7.0
------
NOTE NOTE NOTE: Backwards compatibility for auto-upgrade is BROKEN
    You must manually scp this file over any version 1.6.x or else
    IT WILL BREAK!
    To prevent auto-update from running unset BASHRC_VER
Added new decoding routine for BSD (b64decode)
Switched to tabs instead of 4 spaces for whitespace
Added safety net when updating bashrc
Fixed potential echo portability problems
Changed BASHRC format to be more proper Base64 encoding
Check for GNU before aliasing {mv,cp,rm}; caused problems on *BSD
Replace all "echo -e" references with "printf"
Replace all "unlink" references with "rm -f"
Replaced old version check hack using sort with more proper method

v1.6.5
------
Updating description for Jeff

v1.6.4
------
Moved environment preservation into function (mkenv)

v1.6.3
------
Minor update to custom cd to fix dirs not catching targets with spaces

v1.6.2
------
Added protection to my cd when ~ was passed in (like via jd)

v1.6.1
------
auto-update now saves old copy to $HOME/.bashrc.old

v1.6.0
------
Added auto-update support.  Must configure ssh to pass and sshd to
receive the BASHRC and BASHRC_VER environment variables

v1.5.3
------
Added support for KRB5 to and cleaned up logic for creation of .env.sh

v1.5.2
------
Broke PS1 down into manageable code bits for easier reading

v1.5.1
------
Added dirs override to give a more functional view of the dirstack

v1.5.0
------
Added jd function to complement cd function.  This makes
breadcrumbs that much more useable
Also fix ever-growing .env-HOSTNAME bug

v1.4.12
-------
Tweak to avoid duplicating /etc/PATH
Also fix cd for directory names containing spaces

v1.4.11
-------
Added TMOUT for auto-logout (This one's for you, Art!)
Added cd function for breadcrumb backtracking

v1.4.10
-------
Tweaks for OS X (BSD?).  Added NowDesigning network

v1.4.9
------
Added alias for gnu compatible id under Solaris

v1.4.8
------
Added network descriptions.  Tweaked login banner

v1.4.7
------
Added Speakeasy network, set timezone (TZ) to America/New_York

v1.4.6
------
Added lots of Solaris compatiblity (sfw package) support

v1.4.5
------
Added check for vim and alias it to vi if found

v1.4.4
------
Added extra ansi text features, cosmetic fixes

v1.4.3
------
Added V-Office network color

v1.4.2
------
Added Moore's Mountain network color

v1.4.1
------
Added missing $HOME to .env preparation

v1.4.0
------
Added slick screen handling from Amako

v1.3.1
------
Fixed bug missing $HOME for .network, misc superficial fixes

v1.3.0
Added check for LD_LIBRARY_PATH, moved shell spacing notation out of color vars and into PS1 (where they belong).  Also check LD_PRELOAD.

v1.2.0
------
Added network color abstraction ($HOME/.network)

v1.1.0
------
Added check for $HOME/.alias

v1.0.0
------
Inital version I cared to tag.  Lots-o-cool-stuff
