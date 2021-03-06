#!/bin/bash
# !!! DO NOT FORGET TO UPDATE LOCAL_BASHRC_VER WHEN COMMITTING CHANGES !!!
LOCAL_BASHRC_VER="1.8.4"

# If not running interactively, don't do anything
if [ -n "$PS1" ]; then

# TODO:
# Add (better) *BSD support
# Add alternate base64 routines (uudecode/uuencode?)
# Compress before encoding to minimize environment size NON-BC!

# Set a safer PATH
# Save off the default PATH
SYSPATH=$PATH

# Construct the user's preferred PATH
NEWPATH=$HOME/bin
# Check for a personal PATH
if [ -r "$HOME/.PATH" ]; then
	# And make sure that it hasn't already been added
	echo $PATH | grep `cat "$HOME/.PATH"` >/dev/null
	[ $? != 0 ] && NEWPATH="$NEWPATH:`cat "$HOME/.PATH"`"
fi

# Check for a system-configured PATH
if [ -r /etc/PATH ]; then
	# And make sure that it hasn't already been added
	echo $PATH | grep `cat /etc/PATH` >/dev/null
	[ $? != 0 ] && NEWPATH=$NEWPATH:`cat /etc/PATH`
fi
# Append the default PATH
PATH=$NEWPATH:$SYSPATH
export PATH

# Set a slightly more restrictive umask
#umask 027

# This function must be defined up top because it's used in the self-propagating
# test below.  Caution! Do not break this functionality and expect auto updates
# to work until all hosts have the new code!

function undo_update {
	echo "Error during update detected." >&2
	cd "$HOME"
	printf "Rolling back from .bashrc.old..." >&2
	[ -r .bashrc.old ] && cp -p .bashrc.old .bashrc && echo "Success." >&2 || echo "Error rolling back .bashrc.old!" >&2
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

	if [ -x "`type -P b64decode`" ]; then
		b64decode -r -p $1
		if [ $? != 0 ]; then
			echo "Unable to decode BASHRC with b64decode.  Aborting update." >&2
			return 1
		fi
	elif [ -x "`type -P perl`" ]; then
		PERL=`type -P perl`;
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

	if [ -x "`type -P perl`" ]; then
		PERL=`type -P perl`;
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
		printf "Updating .bashrc to $BASHRC_VER..." >&2
		mv "$HOME/.bashrc" "$HOME/.bashrc.old"
		trap "undo_update $BASHRC_TMP" ERR
		BASHRC_TMP=`mktemp bashrc-$(id -un)-XXXXXX`
		printf "$BASHRC" > $BASHRC_TMP
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
BASHRC=`encode_file "$HOME/.bashrc" 2>/dev/null`

if [ $? -ne 0 ]; then
	# Since we can't encode a version of our .bashrc, disable auto-propagate
	unset BASHRC BASHRC_VER
else
	export BASHRC
fi

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

# Other nice escape sequences:
# Set xterm (or compatible) titlebar:
# \033]0;foo\007 (replace "foo")
# Set Konsole/iTerm tab name:
# \033]30;foo\007 (replace "foo")
# Set Konsole (KDE 3.5+) tab color:
# \033[28;RGBt (replace RGB with the color hex value in decimal form)
#
# man bash "PROMPTING" to see escape chars that bash will expand (ex. \u or \h)

# Don't forget to surround any escape sequences in PS1 with '[' and ']'
# This allows bash to properly calculate line length


# Security Checks
[ -n "$LD_LIBRARY_PATH" ] &&
	printf "${BRIGHT}${UNDERSCORE}${RED}${BGWHITE}WARNING: LD_LIBRARY_PATH is set: ${LD_LIBRARY_PATH}${NORMAL}\n" >&2
[ -n "$LD_PRELOAD" ] &&
	printf "${BRIGHT}${RED}${BGWHITE}WARNING: LD_PRELOAD is set: ${LD_PRELOAD}${NORMAL}\n" >&2

(echo $PATH | egrep '::|:\.|\.:|:$' > /dev/null) &&
	printf "${BRIGHT}${RED}${BGWHITE}WARNING: \".\" is in your PATH.${NORMAL}\n" >&2

###
# Network color definitions
###
NET_alkaloid=$BGBLUE$ITALIC$BRIGHT$WHITE
DESC_alkaloid="Alkaloid Networks"

NET_mojolingo=$BGBLUE$ITALIC$BRIGHT$WHITE
DESC_mojolingo="Mojo Lingo"

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

NET_sunrise=$BRIGHT$YELLOW$BGBLACK
DESC_sunrise="Sunrise Assisted Living"

NET_horde=$BRIGHT$YELLOW$BGGREEN
DESC_horde="The Horde Project"

NET_nexenta=$BLACK$BGYELLOW
DESC_nexenta="Nexenta/GNU Solaris"

NET_syseff=$MAGENTA
DESC_syseff="System Efficiency"

NET_power=$BGBLUE$ITALIC$BRIGHT$WHITE
DESC_power="Power Home Remodeling"

###
# Create the shell prompt ($PS1)
###
# Color used by all hosts on this network
NETCOLOR=$BRIGHT$WHITE
[ -r "$HOME/.network" ] && eval NETCOLOR=\$NET_`cat "$HOME/.network"`
[ -r "$HOME/.network" ] && eval NETDESC=\$DESC_`cat "$HOME/.network"`

# Find out which terminal device we are on
TERMDEV=`tty | cut -c6-`
RVMSTRING=\$\("rvm current 2>/dev/null"\)
RBENVSTRING=\$\("rbenv version 2>/dev/null |awk '{print \$1}'"\)
GITBRANCH=\$\("git status -bs 2>/dev/null | head -n 1 | cut -d' ' -f2-"\)
APPCLUSTER=\$\("kubectl config current-context"\)

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
	xterm*|screen|cygwin)
		TITLEBAR='\[\033]0;\u@\h:\w\007\]'

		# If we're in an xterm, we might be in Konsole or iTerm
		# Renames the Konsole/iTerm tab to the current hostname
		# followed by '#' if root
		TABNAME="\[\033]30;\h\$([ 0 == \$EUID ] && echo '#')\007\]"

		# Set the screen window title if we are in screen
		if [ "$TERM" == "screen" ]; then
			tmp="${USER}@$(echo ${HOSTNAME}|cut -d. -f1)"
			tmp="${tmp}\$([ 0 == \$EUID ] && echo '#')"
			TABNAME="${TABNAME}"'\[\033k'"${tmp}"'\033\\\]'
			unset tmp
		fi
                # Additionally rename the screen window, if applicable
                
		# Colorizes the Konsole tab to red EUID=0
		TABCOLOR="\[\$([ 0 == \$EUID ] && printf '\033[28;16711680t' || printf '\033[28;0t')\]"
		;;
	*)
		TITLEBAR=''
		TABNAME=''
		TABCOLOR=''
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
TOPLINE="\[${NORMAL}\]\n[\$([ 0 == \$EUID ] && echo \[${BRIGHT}${RED}\] || echo \[${NETCOLOR}\])\u\[${NORMAL}${NETCOLOR}\]@\h:\w\[${NORMAL}\]] (${BRIGHT}${BLUE}${APPCLUSTER}|${GITBRANCH}${NORMAL}${BRIGHT}${WHITE}|${NORMAL}${RED}${RVMSTRING:-null}${RBENVSTRING:-null}${NORMAL})\n"

# Prints "[date time]$ " substituting the current date and time.  "$" will print
# as a red "#" when EUID=0
BOTTOMLINE="[\d \t]\$([ 0 == \$EUID ] && echo \[${BRIGHT}${RED}\] || echo \[${NETCOLOR}\])\\\$\[${NORMAL}\] "

# Colorize the prompt and set the xterm titlebar too
PS1="${PRINTErrCode}${TABCOLOR}${TABNAME}${TITLEBAR}${TOPLINE}${BOTTOMLINE}"

# Attempt to locate GNU versions of common utilities
# Do this first, before any of the below utilities are checked for GNU-ness
[ `type -P gls` ] && LS=gls || LS=ls
[ `type -P ggrep` ] && GREP=ggrep || GREP=grep
[ `type -P gmake` ] && alias make=gmake
[ `type -P gtar` ] && alias tar=gtar
[ `type -P gmv` ] && alias mv='gmv -iv'
[ `type -P gcp` ] && alias cp='gcp -iv'
[ `type -P grm` ] && alias rm='grm -iv'

###
# ls colors
###
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

# Set the colors used by ls.  Useful for dark displays like putty.
LS_COLORS='no=00:fi=00:di=37;44:ln=01;36:pi=40;33:so=01;35:bd=40;33;01:cd=40;33;01:or=01;05;37;41:mi=01;05;37;41:ex=01;32:*.cmd=01;32:*.exe=01;32:*.com=01;32:*.btm=01;32:*.bat=01;32:*.sh=01;32:*.csh=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.bz=01;31:*.tz=01;31:*.rpm=01;31:*.cpio=01;31:*.jpg=01;35:*.gif=01;35:*.bmp=01;35:*.xbm=01;35:*.xpm=01;35:*.png=01;35:*.tif=01;35:';

# For BSD ls
LSCOLORS="HeGxFxDxCxDxDxHBHdehBh"

###
# Environment customization
###
# I like VIM.  If I can't have my VIM, give me VI.
if [ -x "`type -P vim`" ]; then
	VISUAL=`type -P vim`
	alias vi=$VISUAL
elif [ -x "`type -P vi`" ]; then
	VISUAL=`type -P vi`
else
	unset EDITOR VISUAL
fi
# What no VI?  Well then give me ed (blech).
EDITOR=${VISUAL:-ed}

# Less is more.
if [ -x "`type -P less`" ]; then
	# We used to use -A (mouse support; not available on OS X) and -X
	# (disable termcap init) but these are not needed.
	# -R: Allow control characters in output.  This permits shell colors.
	# -i: Case-insensitive searches; ignored if the search contains UC chars
	PAGER="`type -P less` -Ri"
else
	# No Less?  Oh well, just give me the system default
	unset PAGER
fi

# Set distribution-specific options
$LS -N / > /dev/null 2>&1
if [ $? == 0 ]; then
	# Hopefully we've got the GNU version
	LS_OPTIONS="-N --color=tty -T 0 -p"
elif [ "`uname -s`" == "Darwin" ]; then
	# FIXME: Add additional test to detect MacOSX 10.3+; required for colors
	# -G: show colors
	# -p: show file type icons in ls output
	# -o: show flags when used with -l
	LS_OPTIONS="-G -p -O"
	alias top='top -ocpu -s3'
else
	# FIXME: Add test for *BSD and add -o at least
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
alias dir="$LS -l"
alias l="$LS -alF"
alias la="$LS -la"
alias ll="$LS -l"
alias ls-l="$LS -l"
alias ls="$LS $LS_OPTIONS"
alias md='mkdir -p'
alias o='less'
alias rd='rmdir'
alias rehash='hash -r'
alias which='type -P'

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

# If we have a recent version of GNU grep colorize the output
$GREP --version|$GREP GNU >/dev/null 2>&1
if [ $? -eq 0 ]; then
    alias grep="$GREP --color=auto"
fi

# Don't keep a shell history on disk (accidently type a password at the prompt?)
unset HISTFILE HISTFILESIZE
# And save all those wonderful settings from above
export EDITOR PAGER PATH PS1 LS_COLORS LSCOLORS VISUAL

###
# Custom functions
###
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

# Enable quick navigation of the directory stack
# Usage: jd <directory index #>
# Get a list of directory indices using 'dirs' (see below)
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

# Pretty-print a list of directories on the stack, with numeric indices for 'jd'
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

# HP-UX getent compatibility wrapper
if [ `uname -s` == 'HP-UX' ]; then
        function getent
        {
                if [ "$1" == "passwd" ]; then
                        cmd=pwget
                elif [ "$1" == "group" ]; then
                        cmd=grget
                else
                        printf 'Unknown database: %s\n' $1 >&2
                        return 1
                fi

                if [ -n "$2" ]; then
                        grep='| grep $2'
		else
			grep=''
                fi

                # GNU getent(1) seems to return 2 if a key is specified
                # but not found
                $cmd $grep || return 2
        }
fi

# Nexenta wrapper to view/modify ACLs easily
function sls
{
	SUN_PERSONALITY=1 /bin/ls "$@"
}

function schmod
{
	SUN_PERSONALITY=1 /bin/chmod "$@"
}

function nscheck
{
	for i in 1 2 3 4;do
		printf "%s: " dns0${i}
		host $@ dns0${i}.alkaloid.net | grep ' has ' | awk '{print $NF}'
	done
}

# Custom function to run on logout
function _logout
{
	# Check for any host-specific logout script
	[ -r ${HOME}/.bash_logout-${HOSTNAME} ] && \
		. ${HOME}/.bash_logout-${HOSTNAME}
	# Flush Kerberos tickets - just in case
	dkp
}

# Circumvent https://github.com/direnv/direnv/issues/210
shell_session_update() { :; }

# The ~/.bash_logout only runs when a login session (not necessarily all 
# interactive sessions) exits.
[ -r ${HOME}/.bash_logout ] || cat<<EOF>${HOME}/.bash_logout 
_logout
EOF

###
# Common per-user configurables
###
# I like vi capabilites on the command line
set -o vi

# vi mode must come *BEFORE* any additional keybindings
# Keep that neat functionality from emacs mode where CTRL-L clears the screen
bind "\C-l":clear-screen
# Bind ^E to FCEDIT
bind "\C-e":edit-and-execute-command

# Eastern Time Zone
export TZ="America/New_York"
# POSIX C (English)
export LANG=C
# Automatically logout idle shells after 6 minutes
#export TMOUT=360

# Check for bash-completion
# FIXME: more locations? This one is from MacPorts
if [ -f /opt/local/etc/bash_completion ]; then
	. /opt/local/etc/bash_completion
fi

# Start by loading RVM/RBENV support
[ -s /usr/local/rvm/scripts/rvm ] && rvmload=/usr/local/rvm/scripts/rvm
[ -s $HOME/.rvm/scripts/rvm ]     && rvmload=$HOME/.rvm/scripts/rvm
[ -s $HOME/.rbenv/bin/rbenv ]     && rbenvload=$HOME/.rbenv/bin/rbenv
if [ -n "$rvmload" -a -n "$rbenvload" ]; then
  printf "${BRIGHT}${RED}WARNING:${NORMAL} Both rbenv and rvm detected! This will fail. Loading neither.\n" >&2
  unset rvmload
  unset rbenvload
fi
[ -n "$rvmload" ] && . $rvmload
[ -n "$rbenvload" ] && eval "$(rbenv init -)"
unset rvmload
unset rbenvload
[ -r ${HOME}/.venvburrito/startup.sh ] && . ${HOME}/.venvburrito/startup.sh
[ -s "${HOME}/.nvm/nvm.sh" ] && . "${HOME}/.nvm/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
[ -s $HOME/.kiex/scripts/kiex ] && . "$HOME/.kiex/scripts/kiex"

# Support for Heroku Toolbelt
heroku_toolbelt="/usr/local/heroku/bin"
if [ -d $heroku_toolbelt ]; then
  PATH="$PATH:$heroku_toolbelt"
fi

# iTerm2 integration: https://iterm2.com/documentation-shell-integration.html
iterm2_integration_path="$HOME/.iterm2_shell_integration.`basename $SHELL`"
if [ -r $iterm2_integration_path ]; then
  source $iterm2_integration_path
fi

# Check for local environment overrides
[ -r "$HOME/.localenv-$HOSTNAME.sh" ] && . "$HOME/.localenv-$HOSTNAME.sh"

# And finally, remind me which host and OS I'm logged into.
printf "${BRIGHT}${WHITE}$HOSTNAME `uname -rs`${NORMAL} ${NETCOLOR} ${NETDESC} ${NORMAL}\n" >&2

else # Test for non-interactive shells
# We still want to load RVM/RBENV, even in non-interactive mode
[ -s /usr/local/rvm/scripts/rvm ] && rvmload=/usr/local/rvm/scripts/rvm
[ -s $HOME/.rvm/scripts/rvm ]     && rvmload=$HOME/.rvm/scripts/rvm
[ -s $HOME/.rbenv/bin/rbenv ]     && rbenvload=$HOME/.rbenv/bin/rbenv
if [ -n "$rvmload" -a -n "$rbenvload" ]; then
  printf "${BRIGHT}${RED}WARNING:${NORMAL} Both rbenv and rvm detected! This will fail. Loading neither.\n" >&2
  unset rvmload
  unset rbenvload
fi
[ -n "$rvmload" ] && . $rvmload
[ -n "$rbenvload" ] && eval "$(rbenv init -)"
unset rvmload
unset rbenvload
[ -r ${HOME}/.venvburrito/startup.sh ] && . ${HOME}/.venvburrito/startup.sh
[ -s "${HOME}/.nvm/nvm.sh" ] && . "${HOME}/.nvm/nvm.sh"
fi
