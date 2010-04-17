#!/bin/sh

CONFIG=config
KEY_DIR=keys
REPOS_DIR=repos

print_usage ()
{
  cat << EOF
$0 command args
commands:
    list:                 lists all the users and their repos
    add user [repos]:     give write-access to the repos for user, create the user
                          or the repos if needed
    dump:                 dump the new authorized_keys file
    add_key user ssh-key: add the key to the user's keys
    help:                 print this help screen
EOF
}
    
create_repo ()
{
  if [ ! -d "$REPOS_DIR/$1" ]
  then
    echo "Creating hg repo: $REPOS_DIR/$1"
    mkdir -p "$REPOS_DIR/$1"
    cd $_
    hg init
    cd -
  fi
}

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
    create_repo $1
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
    while read LINE
    do 
      USER=$(echo $LINE | sed 's/\([a-zA-Z0-9]*\):.*/\1/')
      REPOS=$(echo $LINE | sed 's/[a-zA-Z0-9]*:\(.*\)/\1/')
      if [ -e "$KEY_DIR/$USER" ]
      then
        cat "$KEY_DIR/$USER" |
          while read KEY
          do 
            echo "command=\"hg-ssh $REPOS\",no-port-forwarding,no-agent-forwarding $KEY"
          done
      else
        echo "No key file for user $USER in $KEY_DIR/$USER"
      fi
    done
}

add_key ()
{
  USER=$1
  shift
  echo $@ >> "$KEY_DIR/$USER"
}

if [ -z $@ ]
then
  print_usage
else
  case $1 in 
    list) cat $CONFIG;;
    add) shift; add_repos $@;;
    dump) dump;;
    add_key) shift; add_key $@;;
    help) echo "Unknown command: $0";;
  esac
fi
