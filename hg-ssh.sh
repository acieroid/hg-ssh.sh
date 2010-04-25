#!/bin/sh

CONFIG=config
KEY_DIR=keys
REPOS_DIR=./

print_usage ()
{
  cat << EOF
$0 command args
commands:
    list                  lists all the users and their repos
    add user [repos]      give write-access to the repos for user, create the 
                          user or the repos if needed
    dump                  dump the new authorized_keys file
    add_key user ssh-key  add the key to the user's keys
    del_user user         delete an user
    del_repos repos       remove repositories from hard drive and configuration
    del_write user repo   remove the write access of one user to a repo
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
    cd - >>/dev/null
  fi
}

user_dont_exists ()
{
  if [[ -z $(grep $1 $CONFIG) ]]
  then
    return 0
  else
    return 1
  fi
}

add_repos ()
{
  USER=$1
  shift
  if user_dont_exists $USER
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
      USER=$(echo $LINE | sed 's/\(^[a-zA-Z0-9]*\):.*/\1/')
      REPOS=$(echo $LINE | sed 's/^[a-zA-Z0-9]*:\(.*\)/\1/' |
                sed "s,^\([a-zA-Z0-9]\),$REPOS_DIR/\1,g" |
                sed "s, \([a-zA-Z0-9]\), $REPOS_DIR/\1,g" )
      if [ -e "$KEY_DIR/$USER" ]
      then
        cat "$KEY_DIR/$USER" |
          while read KEY
          do 
            echo -n "command=\"hg-ssh $REPOS\",no-port-forwarding,"
            echo ",no-X11-forwarding,no-agent-forwarding $KEY"
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

del_repos ()
{
  until [ -z "$1" ]
  do
    sed $CONFIG -i -e "s/$1//"
    sed $CONFIG -i -e "s/  / /" # fix multiple spaces
    echo "Removing $REPOS_DIR/$1"
    rm -rf "$REPOS_DIR/$1"
    shift
  done
}

del_user ()
{
  user_dont_exists $1 && echo "User $1 don't exist" && return 1
  echo "Removing user $1"
  grep -v "^$1:" $CONFIG > $CONFIG.tmp
  mv $CONFIG.tmp $CONFIG
  rm -f $KEYS/$1
}

del_write ()
{
  user_dont_exists $1 && echo "User $1 don't exist" && return 1
  sed $CONFIG -i -e "s/^\($1:.*\)$2\(.*\)$/\1\2/"
}

if [[ -z "$@" ]]
then
  print_usage
else
  case $1 in 
    list) cat $CONFIG;;
    add) shift; add_repos $@;;
    dump) dump;;
    add_key) shift; add_key $@;;
    del_repos) shift; del_repos $@;;
    del_user) shift; del_user $1;;
    del_write) shift; del_write $@;;
    *) print_usage;;
  esac
fi
