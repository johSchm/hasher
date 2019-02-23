#!/bin/bash

# ==========================================================================
# @name     HASH
# @author   JS
# @version  1.1
# @date     February 2019
# ==========================================================================

# --------------------------------------------------------------------------
# [KEY]
# NAME:NAME
# EMAIL:EMAIL
# NOTES:NOTES
# PW:PW
# --------------------------------------------------------------------------

TEXT_RESET='\e[0m'
TEXT_ERROR='\e[31m'
TEXT_HEADER='\e[1m'
NUM_OF_VALUE_DIGITS=22
CHAR_LIST='A-Za-z0-9!#$%&+?@'
TEMP=`getopt -o f:k:a:d:lh --long file:,key:,add:,delete:,list,help \
             -n 'javawrap' -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

FILE="`dirname \"$0\"`/hash.txt"
KEY=""
ADD=""
DELETE=""
LIST=false
HELP=false


# used to handle boolean user inputs
function booleanUserRequest()
{
  if [ ! -z "$1" ] ; then
    read -p "$1 [Y/N]: " INPUT
    if [ "$INPUT" = "y" ] || [ "$INPUT" = "Y" ] || [ "$INPUT" = "" ] ; then
      return 1
    else
      return 0
    fi
  fi
}


while true; do
  case "$1" in
    -f | --file )   FILE="$2";    shift 2 ;;
    -k | --key )    KEY="$2";     shift 2 ;;
    -a | --add )    ADD="$2";     shift 2 ;;
    -d | --delete ) DELETE="$2";  shift 2 ;;
    -l | --list )   LIST=true;    shift ;;
    -h | --help )   HELP=true;    shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

# help
if $HELP ; then
  echo -e "\n\t${TEXT_HEADER}HASH by JS${TEXT_RESET}\n"
  echo -e "\t-f, --file\t\tSpecify a certain file to be used."
  echo -e "\t-k, --key\t\tSearches for a key value and return the stored value."
  echo -e "\t-a, --add\t\tAdd a key with a connected value."
  echo -e "\t-d, --delete\t\tDelete a certain entry."
  echo -e "\t-l, --list\t\tList all stored keys."
  echo -e "\t-h, --help\t\tDisplay help information."
  echo -e "\n"

else

  # refractor file string if needed
  if [[ $FILE =~ ".enc" ]] ; then
    FILE=${FILE%.enc}
  fi

  # file doesnt exist
  if [ ! -e "$FILE.enc" ] ; then
    echo -e "[${TEXT_ERROR}ERROR${TEXT_RESET}]: File $FILE not found or not specified!"
    booleanUserRequest "Do you want to create it?"
    if [[ $? -eq 1 ]] ; then # true
      touch $FILE $FILE.enc $FILE.enc.backup
    fi

  # file exists
  else
    echo "Loading file: $FILE.enc"
    cp $FILE.enc $FILE.enc.backup
    openssl enc -aes-256-cbc -pbkdf2 -d -in $FILE.enc -out $FILE
  fi

  # get key value
  if [ ! -z "$KEY" ] ; then
    VALUES=$(awk -v key="[$KEY]" '$0==key { for (i = 1; i <= 4; i++) { getline; print $0 } }' $FILE)
    if [ -z "$VALUES" ] ; then
      echo -e "[${TEXT_ERROR}ERROR${TEXT_RESET}]: Key not found!"
    else
      VALARR=(${VALUES})
      echo -e "Uname:\t${VALARR[0]}"
      echo -e "Email:\t${VALARR[1]}"
      echo -e "Descr:\t${VALARR[2]}"
      echo -e "Passw:\t${VALARR[3]}"
    fi

  # add entry
  elif [ ! -z "$ADD" ] ; then
    echo "[$ADD]" >> $FILE
    read -p 'Uname: ' UNAME
    read -p 'Email: ' EMAIL
    read -p 'Descr: ' DESCR
    if [[ -z "$UNAME" ]] ; then UNAME="none" ; fi
    if [[ -z "$EMAIL" ]] ; then EMAIL="none" ; fi
    if [[ -z "$DESCR" ]] ; then DESCR="none" ; fi
    echo -e "$UNAME\n$EMAIL\n$DESCR" >> $FILE
    echo $(</dev/urandom tr -dc $CHAR_LIST | head -c $NUM_OF_VALUE_DIGITS) >> $FILE
    openssl enc -aes-256-cbc -pbkdf2 -in $FILE -out $FILE.enc

  # delete entry
  elif [ ! -z "$DELETE" ] ; then
    LINENUM=1
    while read LINE ; do
      if [ $LINENUM -eq $(cat $FILE | wc -l) ] ; then
        echo -e "[${TEXT_ERROR}ERROR${TEXT_RESET}]: Key not found!"
        break
      elif [[ $LINE == "[$DELETE]" ]] ; then
        for (( i=$LINENUM; i <= ($LINENUM+4); i++ )) ; do
          sed -i -e "${LINENUM}d" $FILE
        done
      fi
      ((LINENUM++))
    done < $FILE
    openssl enc -aes-256-cbc -pbkdf2 -in $FILE -out $FILE.enc

    # list keys
    elif $LIST ; then
      while read LINE; do
        if [[ "$LINE" =~ ^\[.*\]$ ]] ; then
          echo $LINE
        fi
      done < $FILE

    # nothing to do
    else
      echo -e "[${TEXT_ERROR}ERROR${TEXT_RESET}]: Nothing to do!"
    fi

  rm $FILE
fi
