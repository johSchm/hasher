#!/bin/bash

# ==========================================================================
# @name     HASH
# @author   JS
# @version  1.2
# @date     July 2019
# ==========================================================================

# --------------------------------------------------------------------------
# [KEY]
# NAME:NAME
# EMAIL:EMAIL
# NOTES:NOTES
# PW:PW
# --------------------------------------------------------------------------

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

TEXT_RESET='\e[0m'
TEXT_ERROR='\e[31m'
TEXT_HEADER='\e[1m'
NUM_OF_VALUE_DIGITS=22
CHAR_LIST='A-Za-z0-9!#$%&+?@'
TEMP=`getopt -o f:k:a:d:e:lch --long file:,key:,add:,delete:,edit:,list,clipboard,help \
             -n 'javawrap' -- "$@"`

FILE="`dirname \"$0\"`/hash.txt"
KEY=""
ADD=""
DELETE=""
EDIT=""
LIST=false
CLIPBOARD=false
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


# display help text
function displayHelp()
{
  echo -e "\n\t${TEXT_HEADER}HASH by JS${TEXT_RESET}\n"
  echo -e "\t-f, --file\t\tSpecify a certain file to be used."
  echo -e "\t-k, --key\t\tSearches for a key value and return the stored value."
  echo -e "\t-a, --add\t\tAdd a key with a connected value."
  echo -e "\t-d, --delete\t\tDelete a certain entry."
  echo -e "\t-l, --list\t\tList all stored keys."
  echo -e "\t-c, --clipboard\t\tAdd the key to the clipboard and hide the visual output."
  echo -e "\t-e, --edit\t\tEnter edit mode for a certain key."
  echo -e "\t-h, --help\t\tDisplay help information."
  echo -e "\n"
}


# loads encryped file
function loadFile()
{
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
}


# prints key related information visually as shell output
function printKeyInfo()
{
  readKeyRelatedValues
  echo -e "Uname:\t${VALARR[0]}"
  echo -e "Email:\t${VALARR[1]}"
  echo -e "Descr:\t${VALARR[2]}"
  echo -e "Passw:\t${VALARR[3]}"
}


# returns the values (array) of the certain key
VALARR=[]
function readKeyRelatedValues()
{
  VALUES=$(awk -v key="[$KEY]" '$0==key { for (i = 1; i <= 4; i++) { getline; print $0 } }' $FILE)
  if [ -z "$VALUES" ] ; then
    echo -e "[${TEXT_ERROR}ERROR${TEXT_RESET}]: Key ${KEY} not found!"
  else
    VALARR=(${VALUES})
  fi
}


# add key to the clipboard
function addKeyToClipboard()
{
  readKeyRelatedValues
  echo ${VALARR[3]} | tr -d '\n' | xclip -selection c
}


# redirect the output to an appropriated output method
function outputKeyInfo()
{
  if $CLIPBOARD ; then
    addKeyToClipboard
  else
    printKeyInfo
  fi
}


# edit key related informations
function editEntry()
{
  KEY=${EDIT}
  readKeyRelatedValues
  read -p "Uname: " -e -i ${VALARR[0]} UNAME
  read -p "Email: " -e -i ${VALARR[1]} EMAIL
  read -p "Descr: " -e -i ${VALARR[2]} DESCR

  PASSW=""
  booleanUserRequest "Use password auto gen?"
  if [[ $? -eq 1 ]] ; then # true
    PASSW=$(</dev/urandom tr -dc $CHAR_LIST | head -c $NUM_OF_VALUE_DIGITS)
  else
    read -p "Passw: " -e -i ${VALARR[3]} PASSW
  fi

  LINENUM=1
  while read LINE ; do
    if [ $LINENUM -eq $(cat $FILE | wc -l) ] ; then
      echo -e "[${TEXT_ERROR}ERROR${TEXT_RESET}]: Key ${EDIT} not found!"
      break
    elif [[ $LINE == "[$EDIT]" ]] ; then
      for (( i=$LINENUM; i <= ($LINENUM+4); i++ )) ; do
        sed -i -e "${LINENUM}d" $FILE
      done
    fi
    ((LINENUM++))
  done < $FILE

  echo "[$EDIT]" >> $FILE
  if [[ -z "$UNAME" ]] ; then UNAME="none" ; fi
  if [[ -z "$EMAIL" ]] ; then EMAIL="none" ; fi
  if [[ -z "$DESCR" ]] ; then DESCR="none" ; fi
  if [[ -z "$PASSW" ]] ; then PASSW="none" ; fi
  echo -e "$UNAME\n$EMAIL\n$DESCR\n$PASSW" >> $FILE
  openssl enc -aes-256-cbc -pbkdf2 -in $FILE -out $FILE.enc
}


# add new entry
function addEntry()
{
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
}


# delete entry
function deleteEntry()
{
  LINENUM=1
  while read LINE ; do
    if [ $LINENUM -eq $(cat $FILE | wc -l) ] ; then
      echo -e "[${TEXT_ERROR}ERROR${TEXT_RESET}]: Key ${DELETE} not found!"
      break
    elif [[ $LINE == "[$DELETE]" ]] ; then
      for (( i=$LINENUM; i <= ($LINENUM+4); i++ )) ; do
        sed -i -e "${LINENUM}d" $FILE
      done
    fi
    ((LINENUM++))
  done < $FILE
  openssl enc -aes-256-cbc -pbkdf2 -in $FILE -out $FILE.enc
}


# list all entries
function listEntries()
{
  while read LINE; do
    if [[ "$LINE" =~ ^\[.*\]$ ]] ; then
      echo $LINE
    fi
  done < $FILE
}


# get password
PASS=""
function getPassword()
{
  set +o history
  unset PASS || exit 1
  read -sp 'Enter password: ' PASS; echo
}


# Decrypt the file
function decrypt()
{
  exec 3<<<"$PASS"
  openssl enc -d -aes-256-cbc -pass fd:3 -pbkdf2 -in $FILE.enc -out $FILE
}


# Encrypt the file
function encrypt()
{
  exec 4<<<"$PASS"
  openssl enc -e -aes-256-cbc -pass fd:4 -pbkdf2 -in $FILE -out $FILE.enc
}


while true; do
  case "$1" in
    -f | --file )       FILE="$2";      shift 2 ;;
    -k | --key )        KEY="$2";       shift 2 ;;
    -a | --add )        ADD="$2";       shift 2 ;;
    -d | --delete )     DELETE="$2";    shift 2 ;;
    -e | --edit )       EDIT="$2";      shift 2 ;;
    -l | --list )       LIST=true;      shift ;;
    -c | --clipboard )  CLIPBOARD=true; shift ;;
    -h | --help )       HELP=true;      shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

if $HELP ; then
  displayHelp
else
  loadFile
  if [ ! -z "$KEY" ] ; then
    outputKeyInfo
  elif [ ! -z "$ADD" ] ; then
    addEntry
  elif [ ! -z "$DELETE" ] ; then
    deleteEntry
  elif [ ! -z "$EDIT" ] ; then
    editEntry
  elif $LIST ; then
    listEntries
  else
    echo -e "[${TEXT_ERROR}ERROR${TEXT_RESET}]: Nothing to do!"
  fi
  rm $FILE
fi
