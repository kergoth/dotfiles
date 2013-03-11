#!/bin/bash
#
# Very crude and simple (well, not so simple anymore) script to run 'diff'
# against the 'last' version of a local Dropbox file. This is a 'fragile'
# script and likely to break whenever www.dropbox.com changes its web interface.
# http://wiki.dropbox.com/DropboxAddons/DropDiff
#
# Initial version written 11th July 2010, by Andrew Scheller
# Updated 13th September 2010, by Andrew Scheller
# Updated 8th October 2010, by Andrew Scheller
# Updated 22nd December 2010, by Andrew Scheller
# Updated 4th May 2011, by Andrew Scheller
# Updated 12th May 2011, by Andrew Scheller. Scroll to the bottom for licensing and contact info.
#

function show_usage {
  cat >&2 <<EndUsage
Usage: $(basename $0) [OPTION]... LOCALFILE
Compares LOCALFILE to the previous version in your Dropbox account

  -h                    Show this help
  -d                    Don't keep cookies after script exits
  -w                    Force usage of wget instead of curl
  -c                    Force usage of curl instead of wget
  -u username           Login with specified username
  -p password           Login with specified password
EndUsage
}

# If you want the script to never prompt interactively, either set these
# values here or on the command line
# Otherwise, the script will ask you for them if the login cookie is invalid
# If you set just the USER, the script will ask for just the PASSWORD
SET_DROPBOX_USER=
SET_DROPBOX_PASSWORD=

# The file where we store the dropbox login cookies
DROPBOX_COOKIEJAR=~/.dropbox_login_cookies.txt

# Set this to 1 (or give the -d option) to automatically delete cookies after the script has finished
DELETE_COOKIEJAR=0

# hardcode one of these binary locations (or set in the environment) if you don't want to use the one found in PATH
#WGET=
#CURL=
#DIFF=

# Any extra arguments to pass to the diff command
DIFF_OPTS=

QUIET=0

# standard function from http://wiki.dropbox.com/DropboxAddons/get_dropbox_folder
function get_dropbox_folder {
  [ -n "$DROPBOX_FOLDER" ] && return
  local SQLITE3=$( which sqlite3 )
  if [ -z "$SQLITE3" ]
  then
    echo "Please install sqlite3" >&2
    exit 1
  fi
  # which database have we got?
  if [ -f "$HOME/.dropbox/config.db" ]
  then
    local DBFILE="$HOME/.dropbox/config.db"
    local DBVER=$( "$SQLITE3" "$DBFILE" 'SELECT value FROM config WHERE key="config_schema_version"' )
  elif [ -f "$HOME/.dropbox/dropbox.db" ]
  then
    local DBFILE="$HOME/.dropbox/dropbox.db"
    local DBVER=0
  else
    echo "Dropbox database not found, is dropbox installed?" >&2
    exit 1
  fi
  # get the desired value
  if [ $DBVER -eq 0 ]
  then
    local DBVALUE=$( "$SQLITE3" "$DBFILE" 'SELECT value FROM config WHERE key="dropbox_path"' )
  elif [ $DBVER -eq 1 ]
  then
    local DBVALUE=$( "$SQLITE3" "$DBFILE" 'SELECT value FROM config WHERE key="dropbox_path"' )
  else
    echo "Unhandled DB schema version $DBVER" >&2
    exit 1
  fi
  # decode the value as necessary
  if [ -z "$DBVALUE" ]
  then
    DROPBOX_FOLDER="$HOME/Dropbox"
  else
    if [ $DBVER -eq 0 ]
    then
      local RECODE=$( which recode )
      local UUDECODE=$( which uudecode )
      local PERL=$( which perl )
      if [ "$RECODE" ]
      then
        DROPBOX_FOLDER=$( echo "$DBVALUE" | "$RECODE" /b64.. | head -1 | sed s/.// )
      elif [ "$UUDECODE" ]
      then
        DROPBOX_FOLDER=$( printf 'begin-base64 0 -\n%s\n====\n' "$DBVALUE" | "$UUDECODE" | head -1 | sed s/.// )
      elif [ "$PERL" ]
      then
        DROPBOX_FOLDER=$( "$PERL" -MMIME::Base64 -e "print decode_base64('$DBVALUE')" | head -1 | sed s/.// )
      else
        echo "Please install one of either recode, uudecode or perl" >&2
        exit 1
      fi
    elif [ $DBVER -eq 1 ]
    then
      DROPBOX_FOLDER="$DBVALUE"
    else
      echo "Unhandled DB schema version $DBVER" >&2
      exit 1
    fi
  fi
}

# tweaked function from http://sites.google.com/site/jdisnard/realpath
function real_path {
  local OIFS=$IFS
  IFS='/'
  if [ ! -e "$1" ]
    then
         if [ -h "$1" ]
           then echo "$1: Too many levels of symbolic links" >&2
           else echo "$1: No such file or directory" >&2
         fi
         exit 1
  fi
  local P
  case $1 in
       /*) P=$1 ;;
       *) P=$PWD/$1 ;;
  esac
  local FOO=/
  local I
  for I in $P
  do
    # Resolve relative path punctuation.
    if [ "$I" = "." ] || [ -z "$I" ]
      then continue
    elif [ "$I" = ".." ]
      then FOO=${FOO%/*}
           if [ -z "$FOO" ]
             then FOO=/
           fi
           continue
      else
           if [ "$FOO" = "/" ]
             then FOO="$FOO$I"
             else FOO="$FOO/$I"
           fi
    fi
    # Dereference symbolic links.
    if [ -h "$FOO" ] && [ -x "/bin/ls" ]
      then IFS=$OIFS
           set `/bin/ls -l "$FOO"`
           while shift
           do
             if [ "$1" = "->" ]
               then shift
                    case $1 in
                         /*) FOO=`real_path "$*"` ;;
                         *) FOO=`real_path "${FOO%/*}/$*"` ;;
                    esac
                    shift $#
                    break
             fi
           done
    fi
  done
  IFS=$OIFS
  echo "$FOO"
}

# tweaked function from http://blogs.gnome.org/shaunm/2009/12/05/urlencode-and-urldecode-in-sh/comment-page-1/#comment-421
function urlencode {
  local ARG="$1"
  local LANG=C
  while [[ "$ARG" =~ ^([0-9a-zA-Z/:_\.\-]*)([^0-9a-zA-Z/:_\.\-])(.*) ]] ; do
    echo -n "${BASH_REMATCH[1]}"
    printf "%%%X" "'${BASH_REMATCH[2]}'"
    ARG="${BASH_REMATCH[3]}"
  done
  # the remaining part
  echo -n "$ARG"
}

# standard functions from http://wiki.dropbox.com/DropboxAddons/DropCookie
function delete_dropbox_cookies {
  local COOKIEJAR="$1"
  rm -f "$COOKIEJAR"
}

function check_dropbox_cookies {
  local COOKIEJAR="$1"
  if [ -z "$WGET" ] && [ -z "$CURL" ]
  then
    echo "Please install either wget or curl" >&2
    exit 1
  fi
  local TESTURL="https://www.dropbox.com/home"
  local RESULTPAGE
  if [ "$WGET" ]
  then
    RESULTPAGE=$( "$WGET" -nv --load-cookies "$COOKIEJAR" "$TESTURL" -O - )
  elif [ "$CURL" ]
  then
    RESULTPAGE=$( "$CURL" -s --cookie "$COOKIEJAR" "$TESTURL" )
  fi
  echo -n "$RESULTPAGE" | grep "<meta http-equiv=refresh content=\"0; URL=/login?cont=https%3A//www.dropbox.com/home\" />" > /dev/null
}

function get_dropbox_cookies {
  local COOKIEJAR="$1"
  if [ -z "$WGET" ] && [ -z "$CURL" ]
  then
    echo "Please install either wget or curl" >&2
    exit 1
  fi
  if [ -f "$COOKIEJAR" ]
  then
    # Check cookies are actually valid
    check_dropbox_cookies "$COOKIEJAR"
    if [ $? -eq 0 ]
    then
      echo "Invalid Dropbox cookies in '$COOKIEJAR'" >&2
      delete_dropbox_cookies "$COOKIEJAR"
    fi
  fi
  # Get the cookies
  local TEMP_COOKIES="$COOKIEJAR.tmp"
  local RETRIES=0
  local MAX_RETRIES=3
  while [ ! -f "$COOKIEJAR" ] && [ $RETRIES -lt $MAX_RETRIES ]
  do
    # Login to the Dropbox account
    if [ -z $SET_DROPBOX_USER ] || [ -z $SET_DROPBOX_PASSWORD ]
    then
      echo "Sign in with your Dropbox account"
    fi
    if [ -z $SET_DROPBOX_USER ]
    then
      echo -n "Email: "
      read DROPBOX_USER
    else
      DROPBOX_USER=$SET_DROPBOX_USER
    fi
    if [ -z $SET_DROPBOX_PASSWORD ]
    then
      if [ ! -z $SET_DROPBOX_USER ]
      then
        echo "Email: $SET_DROPBOX_USER"
      fi
      echo -n "Password: "
      local OSTTY=$( stty -g )
      stty -echo
      read DROPBOX_PASSWORD
      stty $OSTTY
      echo
    else
      DROPBOX_PASSWORD=$SET_DROPBOX_PASSWORD
    fi
    if [ $QUIET -eq 0 ]
    then
      echo "Getting cookies for the $DROPBOX_USER Dropbox account..."
    fi
    local LOGINURL="https://www.dropbox.com/login"
    if [ "$WGET" ]
    then
      "$WGET" -nv --keep-session-cookies --save-cookies "$TEMP_COOKIES" --post-data="login_email=$(urlencode $DROPBOX_USER)&login_password=$(urlencode $DROPBOX_PASSWORD)" "$LOGINURL" -O /dev/null
    elif [ "$CURL" ]
    then
      "$CURL" -s --cookie-jar "$TEMP_COOKIES.curl" --data-urlencode "login_email=$DROPBOX_USER" --data-urlencode "login_password=$DROPBOX_PASSWORD" "$LOGINURL" -o /dev/null
      if [ -f "$TEMP_COOKIES.curl" ]
      then
        cat "$TEMP_COOKIES.curl" | sed s,^#HttpOnly_,, > "$TEMP_COOKIES"
        rm "$TEMP_COOKIES.curl"
      fi
    fi
    # pull out just the cookies we need
    if [ -f "$TEMP_COOKIES" ]
    then
      grep "	\(jar\|lid\|touch\)	" "$TEMP_COOKIES" > "$COOKIEJAR"
      rm "$TEMP_COOKIES"
    fi
    # Check login was successful
    check_dropbox_cookies "$COOKIEJAR"
    if [ $? -eq 0 ]
    then
      echo "Login failed" >&2
      RETRIES=$(( $RETRIES + 1 ))
      delete_dropbox_cookies "$COOKIEJAR"
    fi
  done
  if [ $RETRIES -ge $MAX_RETRIES ]
  then
    exit 1
  fi
}

function delete_cookies_on_exit {
  if [ $DELETE_COOKIEJAR -ne 0 ]
  then
    if [ $QUIET -eq 0 ]
    then
      echo "Deleting cookies"
    fi
    delete_dropbox_cookies "$DROPBOX_COOKIEJAR"
  fi
}

# parse command-line options
while getopts dcwhu:p: opt
do
  case "$opt" in
  d)  DELETE_COOKIEJAR=1;;
  w)  if [ ! -z "$CURL" ]
      then
        echo "Can't force usage of both wget and curl at the same time" >&2
        exit 1
      fi
      if [ -z "$WGET" ]
      then
        WGET=`which wget`
        if [ -z "$WGET" ]
        then
          echo "wget not installed" >&2
          exit 1
        fi
      fi
      ;;
  c)  if [ ! -z "$WGET" ]
      then
        echo "Can't force usage of both wget and curl at the same time" >&2
        exit 1
      fi
      if [ -z "$CURL" ]
      then
        CURL=`which curl`
        if [ -z "$CURL" ]
        then
          echo "curl not installed" >&2
          exit 1
        fi
      fi
      ;;
  u)  SET_DROPBOX_USER="$OPTARG";;
  p)  SET_DROPBOX_PASSWORD="$OPTARG";;
  h|\?)
      show_usage
      exit 1;;
  esac
done
shift $(( $OPTIND - 1 ))

if [ -z "$WGET" ] && [ -z "$CURL" ]
then
  WGET=$( which wget )
  if [ -z "$WGET" ]
  then
    CURL=$( which curl )
    if [ -z "$CURL" ]
    then
      echo "Please install either wget or curl" >&2
      exit 1
    fi
  fi
fi

if [ -z "$DIFF" ]
then
  DIFF=$( which diff )
  if [ -z "$DIFF" ]
  then
    echo "Please install diff" >&2
    exit 1
  fi
fi

# start of the main script
if [ $# -ne 1 ]
then
  show_usage
  exit 1
else
  LOCAL_PATH="$1"
  # Check the path is inside the dropbox folder
  if [ -e "$LOCAL_PATH" ]
  then
    if [ -f "$LOCAL_PATH" ]
    then
      LOCAL_PATH=$( real_path "$LOCAL_PATH" )
      LOCAL_PATH_LENGTH=${#LOCAL_PATH}
      get_dropbox_folder
      ROOT_LENGTH=${#DROPBOX_FOLDER}
      if [ $LOCAL_PATH_LENGTH -gt $ROOT_LENGTH ] && [ "${LOCAL_PATH:0:$ROOT_LENGTH}" = "$DROPBOX_FOLDER" ]
      then
        FILE_LENGTH=$(( $LOCAL_PATH_LENGTH - $ROOT_LENGTH - 1 ))
        FILE_ONLY=$( echo ${LOCAL_PATH: -$FILE_LENGTH} | sed s,\ ,%20,g )
        get_dropbox_cookies "$DROPBOX_COOKIEJAR"
        # Get array of URLS to previous revisions of this file
        REVISIONSURL="https://www.dropbox.com/revisions/$FILE_ONLY"
        if [ "$WGET" ]
        then
          REVLIST=$( "$WGET" -nv --load-cookies "$DROPBOX_COOKIEJAR" "$REVISIONSURL" -O - )
        elif [ "$CURL" ]
        then
          REVLIST=$( "$CURL" -s --cookie "$DROPBOX_COOKIEJAR" "$REVISIONSURL" )
        fi
        OLD_FILES=($( echo -n "$REVLIST" | grep "s_magnifier" | cut -d'"' -f2 ))
        OLD_FILES_COUNT=${#OLD_FILES[@]}
        if [ $OLD_FILES_COUNT -ge 2 ]
        then
          TMPFILE=$(mktemp)
          # URL of second-newest file (i.e. not latest)
          LAST_FILE_URL=${OLD_FILES[1]}
          if [ "$WGET" ]
          then
            "$WGET" -nv --load-cookies "$DROPBOX_COOKIEJAR" "$LAST_FILE_URL" -O "$TMPFILE"
          elif [ "$CURL" ]
          then
            "$CURL" -s --cookie "$DROPBOX_COOKIEJAR" "$LAST_FILE_URL" -o "$TMPFILE"
          fi
          # Finally - the user-visible diff
          "$DIFF" $DIFF_OPTS "$TMPFILE" "$LOCAL_PATH"
          rm $TMPFILE
        else
          echo "No older version of \"$LOCAL_PATH\" is stored in Dropbox"
        fi
        delete_cookies_on_exit
      else
        echo "\"$LOCAL_PATH\" isn't inside your Dropbox folder \"$DROPBOX_FOLDER\"" >&2
        exit 1
      fi
    else
      echo "\"$LOCAL_PATH\" isn't a file" >&2
      exit 1
    fi
  else
    echo "\"$LOCAL_PATH\" doesn't exist" >&2
    exit 1
  fi
fi


# This script is licensed under GPL v3:
: <<LICENSEBLOCK
Copyright 2010, 2011 Andrew Scheller.
Visit my website for contact info: http://www.andrewscheller.co.uk

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
LICENSEBLOCK


# The original real_path function (which I've made fixes to) comes with this license:
: <<LICENSEBLOCK2
Copyright 2010 Jon Disnard. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are
permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice, this list of
      conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice, this list
      of conditions and the following disclaimer in the documentation and/or other materials
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY Jon Disnard ``AS IS'' AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those of the
authors and should not be interpreted as representing official policies, either expressed
or implied, of Jon Disnard.
LICENSEBLOCK2


