#!/bin/sh

CONFIG=config
KEY_DIR=keys/

add_repos ()
{
  USER=$1
  shift
  if [[ -z $(grep $USER $CONFIG) ]]
  then
    echo "Adding user $USER"
    echo "$USER:" >> $CONFIG
  fi

  until [ -z "$1" ]
  do
    if [[ -z $(grep $USER $CONFIG | grep $1) ]]
    then
      echo "Adding repo $1 for $USER"
      sed $CONFIG -i -e "s/$USER:/$USER:$1 /"
    else
      echo "Repo $1 already writable by $USER"
    fi
    shift
  done
}

dump ()
{
  cat config |
    while read line
    do 
      USER=$(echo $line | sed 's/\([a-zA-Z0-9]*\):.*/\1/')
      REPOS=$(echo $line | sed 's/[a-zA-Z0-9]*:\(.*\)/\1/')
      if [ -e "$KEYS/$USER" ]
      then
        #TODO: multiple keys ?
        echo "command=\"hg-ssh $REPOS\",no-port-forwarding,no-agent-forwarding $KEY"
      else
        echo "No key file for user $USER"
      fi
    done
}

case $1 in 
  list) cat $CONFIG;;
  add) shift; add_repos $@;;
  dump) dump;;
  *) echo "Unknown command: $0";;
esac
