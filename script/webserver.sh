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
sudo gem update --system
sudo gem install -v=2.2.2 rails -y
sudo gem install i18n
# needed for backgroundrb
sudo gem install chronic packet
# debian packaging
sudo apt-get install reprepro fakeroot dpkg-dev dh-make build-essential debootstrap schroot edos-debcheck apt-mirror
#livecd
sudo apt-get install kvm apt-proxy genisoimage squashfs-tools
sudo mkdir /remaster
# generate images and keys, see script/remaster
#backup
sudo apt-get install rsync
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
# start rails apps
/home/$NEWUSERNAME/web2.0/communtu-program/script/web start

