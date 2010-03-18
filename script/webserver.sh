#!/bin/bash
# script for installing communtu on a new server
# Es muss noch nach dem Script die Datei /etc/apache2/sites-enabled/all angepasst werden.
# Weiter muss in der Apache-Config /etc/apache2/apache2.conf hoechstwahrscheinlich das Root-Verzeichnis
# auskommentiert werden.
OLDSERVER=communtu.org
SVNSERVER=trac.communtu.org
OLDUSERNAME=communtu
NEWUSERNAME=communtu
# folder for web projects
mkdir web2.0
# apache und mail
sudo apt-get install apache2
#scp -r $OLDUSERNAME@$OLDSERVER:/etc/apache2/* /etc/apache2/
sudo apt-get install php5 libapache2-mod-python sendmail
sudo a2enmod proxy
sudo /etc/init.d/apache2 restart
# subversion
sudo apt-get install subversion libapache2-svn
# rails
sudo apt-get install ruby rdoc irb libyaml-ruby libzlib-ruby ri libopenssl-ruby sqlite3 libsqlite3-ruby rubygems mongrel
sudo ln -s /usr/bin/gem1.8 /usr/bin/gem
sudo ln -s /var/lib/gems/1.8/bin/rake /usr/bin/
sudo gem update --system
sudo gem install -v=2.2.2 rails -y
sudo gem install i18n
# needed for backgroundrb
sudo gem install chronic packet
# debian packaging
sudo apt-get install reprepro fakeroot dpkg-dev dh-make build-essential debootstrap schroot edos-debcheck apt-mirror
#livecd
sudo apt-get install kvm libdbd-sqlite3-perl genisoimage squashfs-tools python-software-properties
# fix apt-cacher bug, see https://bugs.launchpad.net/ubuntu/+source/apt-cacher/+bug/83987
sudo add-apt-repository ppa:aperomsik/aap-ppa
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install apt-cacher
sudo /etc/init.d/apt-cacher restart

sudo mkdir /remaster
# generate images and keys, see script/remaster
#backup
sudo apt-get install rsync
#Editor Console
sudo apt-get install joe
# mysql server
sudo apt-get install mysql-server libmysql-ruby ruby1.8-dev libmysqlclient15-dev
sudo scp $OLDUSERNAME@$OLDSERVER:/etc/mysql/my.cnf /etc/mysql/my.cnf
sudo /etc/init.d/mysql reload
mysqladmin -u root -p create communtu
ssh $OLDUSERNAME@$OLDSERVER "mysqldump -u admin -p --lock-all-tables --add-drop-table communtu | gzip -c > /home/communtu/web2.0/db.backup.gz"
scp $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/db.backup.gz /home/$NEWUSERNAME/web2.0/communtu-program/
gunzip -c /home/$NEWUSERNAME/web2.0/communtu-program/db.backup.gz | mysql -u root -p communtu
# checkout rails project
cd web2.0
svn co http://$SVNSERVER/svn/communtu-program communtu-program --username commune 
cd ..
scp $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/communtu-program/config/database.yml /home/$NEWUSERNAME/web2.0/communtu-program/config/database.yml
ln -s communtu-program/public/debs/ communtu-packages

# repository of communtu packages and reprepro database
scp -r $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/public/debs/pool /home/$NEWUSERNAME/web2.0/communtu-program/public/debs
scp -r $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/public/debs/dists /home/$NEWUSERNAME/web2.0/communtu-program/public/debs
scp -r $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/debs/db /home/$NEWUSERNAME/web2.0/communtu-program/debs
scp $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/debs/distributions /home/$NEWUSERNAME/web2.0/communtu-program/debs
scp -r $OLDUSERNAME@$OLDSERVER:/home/communtu/web2.0/communtu-program/debs/repos /home/$NEWUSERNAME/web2.0/communtu-program/debs

# keys
scp $OLDUSERNAME@$OLDSERVER:"/home/$OLDUSERNAME/.ssh/*" /home/$NEWUSERNAME/.ssh/

sudo sh -c "ssh $OLDUSERNAME@$OLDSERVER \"sudo cat /root/.ssh/id_rsa\" > /root/.ssh/id_rsa"
sudo sh -c "ssh $OLDUSERNAME@$OLDSERVER \"sudo cat /root/.ssh/id_rsa.pub\" > /root/.ssh/id_rsa.pub"
scp $OLDUSERNAME@$OLDSERVER:"/home/$OLDUSERNAME/.gnupg/*" /home/$NEWUSERNAME/.gnupg/

# old log files
scp -r $OLDUSERNAME@$OLDSERVER:~/web2.0/$OLDUSERNAME/log /home/$NEWUSERNAME/web2.0/communtu-program/log/oldlog

#sudoers
sudo cp script/sudoers/* /usr/bin/
# check whether this works or visudo needs to be used
sudo sh -c "cat script/visudo >> /etc/sudoers"

# rails server init script
sudo cp script/rails /etc/init.d/
sudo update-rc.d rails defaults

# start rails apps
/home/$NEWUSERNAME/web2.0/communtu-program/script/web start

## add the following to crontab
0       5       *       *       *       /home/communtu/web2.0/communtu-program/script/nightly-cron

