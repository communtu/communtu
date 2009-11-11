#!/bin/bash
paths=`cat $HOME/backup.config | tr '\000' '\n' | awk '/IncludeDirectories/ {getline; s=getline; print "" ; while($s ~ /home/) { print " -g "; print $s; s=getline  } }'  |tr -d '\000-\011' |tr -d '\013-\037' | tr '\n' ' '`
comp="--bzip2=9 -Z \*.zip -Z \*.jpg -Z \*.bz2 -Z \*.gz -Z \*.gif -Z \*.png"
fping -q 192.168.178.42
if [ "$?" != "0" ]; then SERVER=bremer-commune.dyndns.org; else SERVER=192.168.178.42; fi
ssh="ssh -i /home/$USER/.ssh/stallman_rsa bc-backup@$SERVER"
cd
case $1 in
	full)
		dar -c - -g "$3" -R "/home/$USER/" -v $comp --key $2 | $ssh "cat > `echo $USER`_full_backup_`date -I`.1.dar" 
		;;
	diff)
		$ssh "name=\`/bin/ls -1 | grep _full_backup_ |grep $USER | /usr/bin/sort -r | /usr/bin/head -1\`; name2=\`basename \$name .1.dar\`; dar $comp -A \$name2 -C - --key $2 --key-ref $2" > /home/$USER/CAT_$USER.1.dar
		dar -c - -A /home/$USER/CAT_$USER -v  --key $2 --key-ref $2 -R "/home/$USER/" -g "$3" $comp | $ssh "cat > `echo $USER`_diff_backup_`date -I`.dar"
		;;
esac


