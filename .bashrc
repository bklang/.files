#!/bin/bash
LOCAL_BASHRC_VER="1.7.4"
#
# !!! DO NOT FORGET TO UPDATE LOCAL_BASHRC_VER WHEN COMMITTING CHANGES !!!
#
# $Id$
# v1.7.4  Cygwin now supported
#         Support ${HOME}s that have a space in the path
#         Reorder sections for usability
#         Check for ":$" in PATH (same as :.)
#         Whitespace, comments
# v1.7.3  Add missing 1.7.3 version tag and alkaloiddev network
#         Rev 420: This one goes out to Bryan
#         Mute perl warnings (deja-vu?)
#         Reset term color after printing PATH warning
#         Allow for local per-host environment override ~/.localenv-$HOSTNAME.sh
#         Added security check for "." in $PATH
#         Allow $HOME/.PATH to precede /etc/PATH
#         Replace /tmp with $TMPDIR, check and set $TMPDIR
#         Modified `lkp` to flag current principal
#         Symlink current TGT to default location
# v1.7.2  Added Kerberos TGT management (akp/lkp/ckp/dkp)
#         Added LANG=C to environment
#         Added cmsc colors
#         Updated voffice colors
# v1.7.1: Added keybinding ^E to FCEDIT
# v1.7.0:     NOTE NOTE NOTE: Backwards compatibility for auto-upgrade is BROKEN
#             You must manually scp this file over any version 1.6.x or else
#             IT WILL BREAK!
#             To prevent auto-update from running unset BASHRC_VER
#         Added new decoding routine for BSD (b64decode)
#         Switched to tabs instead of 4 spaces for whitespace
#         Added safety net when updating bashrc
#         Fixed potential echo portability problems
#         Changed BASHRC format to be more proper Base64 encoding
#         Check for GNU before aliasing {mv,cp,rm}; caused problems on *BSD
#         Replace all "echo -e" references with "printf"
#         Replace all "unlink" references with "rm -f"
#         Replaced old version check hack using sort with more proper method
# v1.6.5: Updating description for Jeff
# v1.6.4: Moved environment preservation into function (mkenv)
# v1.6.3: Minor update to custom cd to fix dirs not catching targets with spaces
# v1.6.2: Added protection to my cd when ~ was passed in (like via jd)
# v1.6.1: auto-update now saves old copy to $HOME/.bashrc.old
# v1.6.0: Added auto-update support.  Must configure ssh to pass and sshd to
#         receive the BASHRC and BASHRC_VER environment variables
# v1.5.3: Added support for KRB5 to and cleaned up logic for creation of .env.sh
# v1.5.2: Broke PS1 down into manageable code bits for easier reading
# v1.5.1: Added dirs override to give a more functional view of the dirstack
# v1.5.0: Added jd function to complement cd function.  This makes
#         breadcrumbs that much more useable
#         Also fix ever-growing .env-HOSTNAME bug
# v1.4.12: Tweak to avoid duplicating /etc/PATH
#          Also fix cd for directory names containing spaces
# v1.4.11: Added TMOUT for auto-logout (This one's for you, Art!)
#          Added cd function for breadcrumb backtracking
# v1.4.10: Tweaks for OS X (BSD?).  Added NowDesigning network
# v1.4.9: Added alias for gnu compatible id under Solaris
# v1.4.8: Added network descriptions.  Tweaked login banner
# v1.4.7: Added Speakeasy network, set timezone (TZ) to America/New_York
# v1.4.6: Added lots of Solaris compatiblity (sfw package) support
# v1.4.5: Added check for vim and alias it to vi if found
# v1.4.4: Added extra ansi text features, cosmetic fixes
# v1.4.3: Added V-Office network color
# v1.4.2: Added Moore's Mountain network color
# v1.4.1: Added missing $HOME to .env preparation
# v1.4: Added slick screen handling from Amako
# v1.3.1: Fixed bug missing $HOME for .network, misc superficial fixes
# v1.3: Added check for LD_LIBRARY_PATH, moved shell spacing notation out of
#       color vars and into PS1 (where they belong).  Also check LD_PRELOAD.
# v1.2: Added network color abstraction ($HOME/.network)
# v1.1: Added check for $HOME/.alias
# v1.0: Inital version I cared to tag.  Lots-o-cool-stuff

# TODO:
# Add (better) *BSD support
# Add alternate base64 routines (uudecode/uuencode?)

# This function must be defined up top because it's used in the self-propagating
# test below.  Caution! Do not break this functionality and expect auto updates
# to work until all hosts have the new code!

function undo_update {
	echo "Error during update detected." >&2
	cd "$HOME"
	echo "Rolling back from .bashrc.bak" >&2
	[ -r .bashrc.bak ] && mv .bashrc.bak .bashrc && echo "Success." >&2
	echo
	echo "If this error persists, unset BASHRC_VER before connecting again." >&2
	echo
	exit 0
}

function decode_file {
	file=$1
	if [ -z "$file" ]; then
		echo "Must specify a file to encode" >&2
		return 1
	fi

	if [ -x "`type -p b64decode`" ]; then
		b64decode -r -p $1
		if [ $? != 0 ]; then
			echo "Unable to decode BASHRC with b64decode.  Aborting update." >&2
			return 1
		fi
	elif [ -x "`type -p perl`" ]; then
		PERL=`type -p perl`;
		 $PERL -e '
			use strict;
			use warnings;

			use MIME::Base64 qw(decode_base64);

			open(FILE, $ARGV[0]) or die "$!";
			while (<FILE>) {
				if ($_ =~ /^begin-base64 644/) { next; }
				if ($_ =~ /^====$/) { last; }
				print decode_base64($_);
			}
		' $file 2>/dev/null
		if [ $? != 0 ]; then
			echo "Unable to decode BASHRC with perl.  Aborting update." >&2
			return 1
		fi
	else
		echo "Unable to locate working base 64 encoder." >&2
		return 1
	fi
}

function encode_file
{
	file=$1
	if [ -z "$file" ]; then
		echo "Must specify a file to encode" >&2
		return 1
	fi

	if [ -x "`type -p perl`" ]; then
		PERL=`type -p perl`;
		 $PERL -e '
			use strict;
			use warnings;

			use MIME::Base64 qw(encode_base64);
			my $buf;

			open(FILE, $ARGV[0]) or die "$!";
			print "begin-base64 644 .bashrc\\n";
			while (read(FILE, $buf, 60*57)) {
				print encode_base64($buf, "\\n");
			}
			print "====\\n";
		' $file 2>/dev/null
	else
		echo "Unable to locate working base 64 encoder." >&2
		return 1
	fi
}

# If BASHRC is already set we've already run
if [ ! -z "$BASHRC_VER" ]; then
	UPDATE=0
	MAJ=`echo $BASHRC_VER | cut -d . -f 1`
	MIN=`echo $BASHRC_VER | cut -d . -f 2`
	REV=`echo $BASHRC_VER | cut -d . -f 3` 
	LOCAL_MAJ=`echo $LOCAL_BASHRC_VER | cut -d . -f 1`
	LOCAL_MIN=`echo $LOCAL_BASHRC_VER | cut -d . -f 2`
	LOCAL_REV=`echo $LOCAL_BASHRC_VER | cut -d . -f 3`
	if [ "$MAJ" -gt "$LOCAL_MAJ" ]; then
		UPDATE=1
	elif [ "$MAJ" -eq "$LOCAL_MAJ" -a "$MIN" -gt "$LOCAL_MIN" ]; then
		UPDATE=1
	elif [ "$MAJ" -eq "$LOCAL_MAJ" -a "$MIN" -eq "$LOCAL_MIN" -a "$REV" -gt "$LOCAL_REV" ]; then
		UPDATE=1;
	fi
	if [ $UPDATE -ne 0 ]; then
		echo "Updating .bashrc to $BASHRC_VER" >&2
		BASHRC_TMP=`mktemp bashrc-$(id -un)-XXXXXX`
		trap "undo_update $BASHRC_TMP" ERR
		printf "$BASHRC" > $BASHRC_TMP
		mv "$HOME/.bashrc" "$HOME/.bashrc.old"
		decode_file $BASHRC_TMP > "$HOME/.bashrc"
		echo "done"
		trap - ERR
		. "$HOME/.bashrc"
		rm -f $BASHRC_TMP
		return 0
	fi
fi
# The local version is the version
export BASHRC_VER=$LOCAL_BASHRC_VER

# Store the current .bashrc in memory for propagation
export BASHRC=`encode_file "$HOME/.bashrc"`


# Set a safer PATH
# Save off the system PATH
SYSPATH=$PATH

# Construct the user's preferred PATH
PATH=/bin:/usr/bin:/sbin:/usr/sbin:$HOME/bin
# Check for a personal PATH
if [ -r "$HOME/.PATH" ]; then
	# And make sure that it hasn't already been added
	echo $PATH | grep `cat "$HOME/.PATH"` >/dev/null
	[ $? != 0 ] && PATH=$PATH:`cat "$HOME/.PATH"`
fi
# Check for a system-configured PATH
if [ -r /etc/PATH ]; then
	# And make sure that it hasn't already been added
	echo $PATH | grep `cat /etc/PATH` >/dev/null
	[ $? != 0 ] && PATH=$PATH:`cat /etc/PATH`
fi
# Append the system PATH
PATH=$PATH:$SYSPATH

# Lets define some pretty colors
BLACK='\033[30m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'

BGBLACK='\033[40m'
BGRED='\033[41m'
BGGREEN='\033[42m'
BGYELLOW='\033[43m'
BGBLUE='\033[44m'
BGMAGENTA='\033[45m'
BGCYAN='\033[46m'
BGWHITE='\033[47m'

BRIGHT='\033[01m'
NORMAL='\033[00m'

ITALIC='\033[03m'
UNDERSCORE='\033[04m'  # only works in xterms
BLINK='\033[05m'	   # doesn't work in xterms
REVERSE='\033[07m'
INVISIBLE='\033[08m'
# \033[x;yH Moves cursor to x,y
# \033[yA Moves cursor up y lines
# \033[yB Moves cursor down y lines
# \033[xC moves cursor right x spaces
# \033[xD moves cursor left x spaces
CLEAR='\033[2J'


# Security Checks
[ -n "$LD_LIBRARY_PATH" ] &&
	printf "${BRIGHT}${UNDERSCORE}${RED}${BGWHITE}WARNING: LD_LIBRARY_PATH is set: ${LD_LIBRARY_PATH}${NORMAL}\n" >&2
[ -n "$LD_PRELOAD" ] &&
	printf "${BRIGHT}${RED}${BGWHITE}WARNING: LD_PRELOAD is set: ${LD_PRELOAD}${NORMAL}\n" >&2

(echo $PATH | egrep '::|:\.|\.:|:$' > /dev/null) &&
	printf "${BRIGHT}${RED}${BGWHITE}WARNING: \".\" is in your PATH.${NORMAL}\n" >&2

# Network color definitions
NET_alkaloid=$ITALIC$BRIGHT$BLUE
DESC_alkaloid="Alkaloid Networks"

NET_alkaloiddev=$BRIGHT$BLUE$BGWHITE
DESC_alkaloiddev="Alkaloid Networks - DEVELOPMENT"

NET_anomaly=$BRIGHT$GREEN
DESC_anomay="Team Anomaly -- Winners of DefCon XI, Interz0ne III RootFu"

NET_blkberry=$BRIGHT$YELLOW
DESC_blkberry="700 Blackberry Ct."

NET_cetlnx=$BRIGHT$WHITE$BGYELLOW
DESC_cetlnx="CET/Linux Labs Intl."

NET_nowdesigning=$BLACK$BGMAGENTA
DESC_nowdesigning=NowDesigning.com

NET_mooremtn=$BRIGHT$MAGENTA
DESC_mooremtn="Moore's Mountain"

NET_motelcom=$BLUE$BGCYAN
DESC_motelcom="Travelogistics/Motel.com"

NET_rhs=$BRIGHT$BLUE$BGWHITE
DESC_rhs="Roswell High School"

NET_stoo=$BRIGHT$CYAN
DESC_stoo="Stoo.org / Tim Stewart"

NET_support=$BRIGHT$MAGENTA
DESC_support="Lucid Interactive / support.alkaloid.net / Jeff Smith"

NET_cmsc=$BGGREEN$BLUE
DESC_cmsc="CedarCrestone"

NET_voffice=$BGWHITE$RED
DESC_voffice="V-Office"

NET_speakez=$BGMAGENTA$BRIGHT$CYAN
DESC_speakez="Speakeasy Networks"

NET_xunion=$GREEN
DESC_xunion="TransUnion"

# Color used by all hosts on this network
NETCOLOR=$BRIGHT$WHITE
[ -r "$HOME/.network" ] && eval NETCOLOR=\$NET_`cat "$HOME/.network"`
[ -r "$HOME/.network" ] && eval NETDESC=\$DESC_`cat "$HOME/.network"`

# Find out which terminal device we are on
TERMDEV=`tty | cut -c6-`

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Solaris version of Linux compatible id
if [ -x /usr/xpg4/bin/id ]; then
	ID="/usr/xpg4/bin/id"
	alias id=$ID
else
	ID="id"
fi

# Prepare the titlebar string if we happen to be on an xterm (or a derivative).
case $TERM in
	xterm*|screen)
		TITLEBAR='\[\033]0;\u@\h:\w\007\]'
		;;
	*)
		TITLEBAR=''
		;;
esac

# Prints "[Last command returned error X]" where X is the return code of the
# last executed program when not 0
PRINTErrCode="\$(returnval=\$?
	if [ \$returnval -ne 0 ]; then
		echo \"\\n\[${BRIGHT}${WHITE}[${RED}\]Last command returned error \$returnval\[${WHITE}\]]\"
	fi)"

# Prints "[user@host:/path/to/cwd] (terminal device)" properly colorized for the
# current network. "user" is printed as red if EUID=0
TOPLINE="\[${NORMAL}\]\n[\$([ \`$ID -u\` == 0 ] && echo \[${BRIGHT}${RED}\] || echo \[${NETCOLOR}\])\u\[${NORMAL}${NETCOLOR}\]@\h:\w\[${NORMAL}\]] (${TERMDEV:-null})\n"

# Prints "[date time]$ " substituting the current date and time.  "$" will print
# as a red "#" when EUID=0
BOTTOMLINE="[\d \t]\$([ \`$ID -u\` == 0 ] && echo \[${BRIGHT}${RED}\] || echo \[${NETCOLOR}\])\\\$\[${NORMAL}\] "

# Colorize the prompt and set the xterm titlebar too
PS1="${TITLEBAR}${PRINTErrCode}${TOPLINE}${BOTTOMLINE}"

# The colors defined below should map as:
# directories: bright white over blue
# symlinks: bright cyan
# sockets: bright magenta
# pipes: bright brown (yellow)
# executables: bright green
# block specials: bright brown (yellow)
# char specials: bright brown (yellow)
# BSD ONLY: SETUID: bright white over red
# BSD ONLY: SETGID: bright white over brown (orange)
# BSD ONLY: "tmp" dirs (world writeable + sticky): black over grey
# BSD ONLY: world writeable dirs: red over grey

# Set the colors used by LS.  Useful for dark displays like putty.
LS_COLORS='no=00:fi=00:di=37;44:ln=01;36:pi=40;33:so=01;35:bd=40;33;01:cd=40;33;01:or=01;05;37;41:mi=01;05;37;41:ex=01;32:*.cmd=01;32:*.exe=01;32:*.com=01;32:*.btm=01;32:*.bat=01;32:*.sh=01;32:*.csh=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.bz=01;31:*.tz=01;31:*.rpm=01;31:*.cpio=01;31:*.jpg=01;35:*.gif=01;35:*.bmp=01;35:*.xbm=01;35:*.xpm=01;35:*.png=01;35:*.tif=01;35:';

# For BSD ls
LSCOLORS="HeGxFxDxCxDxDxHBHdehBh"

# I like VIM.  If I can't have my VIM, give me VI.
if [ -x "`type -p vim`" ]; then
	VISUAL=`type -p vim`
	alias vi=$VISUAL
elif [ -x "`type -p vi`" ]; then
	VISUAL=`type -p vi`
else
	unset EDITOR VISUAL
fi
# What no VI?  Well then give me ed (blech).
EDITOR=${VISUAL:-ed}

# Less is more.
if [ -x "`type -p less`" ]; then
	PAGER="`type -p less` -X"
#else
#	# No Less?  Oh well, just give me the system default
#	unset PAGER
fi

# Set pretty ls options
ls -N / > /dev/null 2>&1
if [ $? == 0 ]; then
	# Hopefully we're got the GNU version
	LS_OPTIONS="-N --color=tty -T 0 -p"
elif [ "`uname -s`" == "Darwin" ]; then
	# FIXME: Add additional test to determine MacOSX 10.3+
	LS_OPTIONS="-G -p"
else
	LS_OPTIONS=""
fi

# Make sure we have defined a temporary directory
[ -z "$TMPDIR" ] && export TMPDIR=/tmp

# Some standard aliases
alias +='pushd .'
alias -- -='popd'
alias ..='cd ..'
alias ...='cd ../..'
alias beep='printf "\007"'
alias dir='ls -l'
alias l='ls -alF'
alias la='ls -la'
alias ll='ls -l'
alias ls='/bin/ls $LS_OPTIONS'
alias ls-l='ls -l'
alias md='mkdir -p'
alias o='less'
alias rd='rmdir'
alias rehash='hash -r'
alias which='type -p'

# Attempt to locate GNU versions of common utilities
[ `type -p gls` ] && alias ls='gls $LS_OPTIONS'
[ `type -p ggrep` ] && alias grep=ggrep
[ `type -p gmake` ] && alias make=gmake
[ `type -p gtar` ] && alias tar=gtar
[ `type -p gmv` ] && alias mv='gmv -iv'
[ `type -p gcp` ] && alias cp='gcp -iv'
[ `type -p grm` ] && alias rm='grm -iv'

# Check for User-Defined aliases:
[ -f "$HOME/.alias" ] && . "$HOME/.alias"

# If we are using the GNU versions of these utilities (cp, mv, rm)...
for util in cp mv rm; do
	$util --version > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		# ...then make them safer (prompt before overwrite, be verbose)
		alias $util="$util -iv"
	fi
done

# Don't keep a shell history on disk (accidently type a password at the prompt?)
unset HISTFILE HISTFILESIZE
# And save all those wonderful settings from above
export EDITOR PAGER PATH PS1 LS_COLORS LSCOLORS VISUAL

# If we're logging in from a session that has an ssh agent, X credentials,
# or a KerberosV credentail cache available, stow them for future screen
# startups.  Ignore this check if we're a screen so we don't mangle the 
# environment with old information
function mkenv
{
	local env="$HOME/.env-$HOSTNAME.sh"
	[ ! -z "$DISPLAY" -o ! -z "$SSH_AUTH_SOCK" -o ! -z "$KRB5CCNAME" ] && \
		rm -f "$env" > /dev/null
	[ ! -z "$DISPLAY" ] && echo "DISPLAY=$DISPLAY" >> "$env"
	[ ! -z "$SSH_AUTH_SOCK" ] && echo "SSH_AUTH_SOCK=$SSH_AUTH_SOCK" >> "$env"
	[ ! -z "$KRB5CCNAME" ] && echo "KRB5CCNAME=$KRB5CCNAME" >> "$env"
}

if [ "$TERM" != "screen" ]; then
	mkenv
else
	# And if an environment is available for screen, use it
	[ "$TERM" == "screen" -a -r "$HOME/.env-$HOSTNAME.sh" ] && \
		. "$HOME/.env-$HOSTNAME.sh"
fi

# Check for local environment overrides
[ -r "$HOME/.localenv-$HOSTNAME.sh" ] && . "$HOME/.localenv-$HOSTNAME.sh"

# Push directory changes on the stack.  This gives us a 'breadcrumb' style
# trail to backtrack.  Should be handy
function cd
{
	DIR=`echo $1 | sed -e "s#^~#$HOME#"`
	if [ -z "$DIR" -o "$DIR" == "~" ]; then
		DIR="$HOME";
	fi
	if [ "$DIR" != "." -a "$DIR" != "`pwd`" ]; then
		# This automatically sets CWD for us.  How Nice.
		pushd "$DIR" > /dev/null
	fi
}

function jd
{
	JUMP=$1
	if [ -z "$JUMP" -o $JUMP -eq 0 ]; then
		popd
	else
		if [ $JUMP -lt 0 ]; then
			# Get the absolute value
			JUMP=`echo $JUMP | sed -e 's/^-//'`
			if [ $JUMP -gt ${#DIRSTACK[*]} ]; then
				echo "Directory stack too shallow for $JUMP level jump." >&2
				return 1
			else
				let LEVEL=${#DIRSTACK[*]}-$JUMP
				cd ${DIRSTACK[$LEVEL]}
			fi
		elif [ $JUMP -gt 0 ]; then
			if [ $JUMP -gt ${#DIRSTACK[*]} ]; then
				echo "Directory stack too shallow for $JUMP level jump." >&2
				return 1
			else
				let LEVEL=$JUMP
				cd "${DIRSTACK[$LEVEL]}"
			fi
		fi
	fi
}

function dirs
{
	i=0;
	while ([ "${DIRSTACK[$i]}" ]); do
		echo "$i: ${DIRSTACK[$i]}"
		i=$(($i + 1));
	done
}

# Add Kerberos principal
function akp
{
	if [ -z "$1" ]; then
		echo "Must specify a realm name for the argument." >&2
		return 1
	fi

	local env="$HOME/.krbcca-$HOSTNAME.sh"
	[ -r "$env" ] && . "$env"

	local cc=`lkp | grep $1|sed -e 's/\*//'|cut -d: -f1`
	if [ -n "$cc" ]; then
		echo "Reusing old credentials cache for $1"
		export KRB5CCNAME=${KRBCCA[$cc]}
		kinit -R ${PRINCS[$i]}
		if [ $? != 0 ]; then
			echo "Error renewing ticket.  Requesting a new one." >&2
			kinit ${PRINCS[$i]}
		fi
	else
		cc=`mktemp $TMPDIR/krb5cc-XXXXXX`
		KRB5CCNAME=$cc kinit $1
		if [ $? == 0 ]; then
			let i=${#PRINCS[*]}+1
			PRINCS[$i]=$1
			KRBCCA[$i]=$cc
			export KRB5CCNAME=${KRBCCA[$i]}
		        if [ ! -z "${KRBCCA[*]}" ]; then
		                i=1
		                printf "KRBCCA=( " > "$env"
		                while ([ "${PRINCS[$i]}" ]); do
		                        printf "[%s]=%s " $i ${KRBCCA[$i]} >> "$env"
		                        let i=$i+1
		                done
		                printf ")\n" >> "$env"
		                i=1
		                printf "PRINCS=( " >> "$env"
		                while ([ "${PRINCS[$i]}" ]); do
		                        printf "[%s]=%s " $i ${PRINCS[$i]} >> "$env"
		                        let i=$i+1
		                done
		                printf ")\n" >> "$env"
		        fi

		fi
	fi
	rm -f $TMPDIR/krb5cc_`id -u`  > /dev/null 2>&1 && \
		ln -s $KRB5CCNAME $TMPDIR/krb5cc_`id -u`
}

# List Kerberos principals
function lkp
{
	local env="$HOME/.krbcca-$HOSTNAME.sh"
	[ -r "$env" ] && . "$env"
        i=1;
        while ([ "${PRINCS[$i]}" ]); do
		if [ "$KRB5CCNAME" == "${KRBCCA[$i]}" ]; then
			printf '*'
		else
			printf ' '
		fi
                printf '%s: %s\n' $i ${PRINCS[$i]}
                i=$(($i + 1));
        done
}

# Destroy Kerberos principals
function dkp
{
	local env="$HOME/.krbcca-$HOSTNAME.sh"
	[ -r "$env" ] && . "$env"
	i=1
	while ([ "${KRBCCA[$i]}" ]); do
		printf 'Destroying credentials for %s\n' ${PRINCS[$i]}
		KRB5CCNAME=${KRBCCA[$i]} kdestroy
		let i=$i+1
	done
	unset KRB5CCNAME KRBCCA PRINCS
	rm -f "$env" > /dev/null 2>&1
}

# Change working Kerberos principal
function ckp
{
	local env="$HOME/.krbcca-$HOSTNAME.sh"
	[ -r "$env" ] && . "$env"
	if [ -z "$1" ]; then
		printf 'Must select Kerberos principal by number' >&2
		lkp
		return 1
	elif [ -n "${PRINCS[$1]}" ]; then
		printf 'Switching to %s\n' ${PRINCS[$1]}
		export KRB5CCNAME=${KRBCCA[$1]}
		rm -f $TMPDIR/krb5cc_`id -u`  > /dev/null 2>&1 && \
			ln -s $KRB5CCNAME $TMPDIR/krb5cc_`id -u`
	else
		printf "Unknown principal index." >&2
		return 1
	fi
}

###
# User configurables
###
# Keep that neat functionality from emacs mode where CTRL-L clears the screen
bind "\C-l":clear-screen
# Bind ^E to FCEDIT
bind "\C-e":edit-and-execute-command

# I like VI capabilites on the command line
set -o vi

# Set a slightly more restrictive umask
umask 027

# Automatically logout idle shells after 6 minutes
#export TMOUT=360

# Eastern Time Zone
export TZ="America/New_York"
# POSIX C (English)
export LANG=C

# And finally, remind me which host and OS I'm logged into.
printf "${BRIGHT}${WHITE}$HOSTNAME `uname -rs`${NORMAL} ${NETCOLOR}${NETDESC}${NORMAL}" >&2
