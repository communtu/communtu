#!/bin/bash

#automatic backup script using dar and a remote server

# determine best server address (intranet or internet?)
ping -q -c 1 192.168.178.42
if [ "$?" != "0" ]; then SERVER=bremer-commune.dyndns.org; else SERVER=192.168.178.42; fi
# how to call the server
# note that you need to install public key authentication, with private key in ~/.ssh/stallman_rsa
ssh="ssh -i $HOME/.ssh/stallman_rsa bc-backup@$SERVER"

# precise time stamp (in case of more than daily backups)
date=`date +%Y-%m-%d--%H:%M:%S`

# full or differential backup?
mode=$1

# read directory list from dar-gui generated config file, if not given as argument
configfile=$HOME/backup.config
passwdfile=$HOME/backup.password
if [ $# -gt 1 ] 
then
  passwd=$2
else
  passwd=`head -1 $passwdfile`
fi
if [ $# -gt 2 ] 
then
  paths="-g $3"
  while [ $# -gt 3 ]; do
    shift
    paths=${paths}" -g $3"
  done
else
  paths=`cat $configfile | tr '\000' '\n' | awk '/IncludeDirectories/ {getline; s=getline; print "" ; while($s ~ /home/) { print " -g "; print $s; s=getline  } }'  |tr -d '\000-\011' |tr -d '\013-\037' | tr '\n' ' ' | sed "s/\/home\/${USER}\///g"`
fi

# do not compress already compressed files
comp="--bzip2=9 -Z \*.zip -Z \*.jpg -Z \*.bz2 -Z \*.gz -Z \*.gif -Z \*.png"

cd

# call dar
case $mode in
	full)
		dar -c - ${paths} -R $HOME -v $comp --key ${passwd} | $ssh "cat > backup_${USER}_${date}_full.1.dar" 
		;;
	diff)
		$ssh "name=\`/bin/ls -1 | grep backup_${USER}_ | /usr/bin/sort -r | /usr/bin/head -1\`; name2=\`basename \$name .1.dar\`; dar $comp -A \$name2 -C - --key ${passwd} --key-ref ${passwd}" > $HOME/CAT_$USER.1.dar
		dar -c - -A $HOME/CAT_$USER -v  --key ${passwd} --key-ref ${passwd} -R $HOME ${paths} $comp | $ssh "cat > backup_${USER}_${date}_diff.1.dar"
		;;
esac


