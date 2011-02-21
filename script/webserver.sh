#!/bin/bash
# script for installing communtu on a new server
# Es muss noch nach dem Script die Datei /etc/apache2/sites-enabled/all angepasst werden.
# Weiter muss in der Apache-Config /etc/apache2/apache2.conf hoechstwahrscheinlich das Root-Verzeichnis
# auskommentiert werden.
OLDDBUSER=root
OLDDBPASSWORD=...
NEWDBUSER=root
NEWDBPASSWORD=...
OLDSERVER=communtu.org
SVNSERVER=trac.communtu.org
OLDUSERNAME=communtu
NEWUSERNAME=communtu
# folder for web projects
cd
mkdir web2.0
# apache und mail
sudo apt-get install apache2 webalizer
mkdir -p webalizer/en-communtu
mkdir -p webalizer/de-communtu
mkdir -p webalizer/fr-communtu
mkdir -p webalizer/pack-communtu

sudo scp $OLDUSERNAME@$OLDSERVER:/etc/apache2/sites-available/communtu.conf /etc/apache2/sites-available/
sudo a2ensite communtu.conf
sudo apt-get install php5 libapache2-mod-python sendmail
sudo a2enmod proxy
# subversion
sudo apt-get install subversion libapache2-svn
sudo /etc/init.d/apache2 restart
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
sudo apt-get install kvm libdbd-sqlite3-perl genisoimage squashfs-tools python-software-properties kpartx

echo 'SSH="ssh -p 2221 -o StrictHostKeyChecking=no -o ConnectTimeout=500 root@localhost"' >> ~/.bashrc
echo 'SCP="scp -P 2221 -o StrictHostKeyChecking=no -o ConnectTimeout=500"' >> ~/.bashrc

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
mysqladmin -u $NEWDBUSER --password=$NEWDBPASSWORD create communtu
ssh $OLDUSERNAME@$OLDSERVER "mysqldump -u $OLDDBUSER --passwod=$OLDDBPASSWORD --lock-all-tables --add-drop-table communtu | gzip -c > /home/communtu/web2.0/db.backup.gz"
scp $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/db.backup.gz /home/$NEWUSERNAME/web2.0/communtu-program/
gunzip -c /home/$NEWUSERNAME/web2.0/communtu-program/db.backup.gz | mysql -u $NEWDBUSER --password=$NEWDBPASSWORD communtu
# checkout rails project
cd web2.0
svn co http://$SVNSERVER/svn/communtu-program communtu-program --username commune
echo 3002 > communtu-program/config/ports
echo 3003 >> communtu-program/config/ports
echo 3004 >> communtu-program/config/ports
echo 3005 >> communtu-program/config/ports
echo 3006 >> communtu-program/config/ports
cp communtu-program/config/database.yml.template communtu-program/config/database.yml
# database user and password
sed -i 's/root/$NEWDBUSER/' communtu-program/config/database.yml
sed -i 's/password: /password: $NEWDBPASSWORD/' communtu-program/config/database.yml
# test system
cp -r communtu-program communtu-program-test
echo 3020 > communtu-program-test/config/ports
sed -i 's/database: communtu/database: communtu-test/' communtu-program-test/config/database.yml
mysqladmin -u $NEWDBUSER --password=$NEWDBPASSWORD create communtu-test
cd ..
# database configuration
scp $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/communtu-program/config/database.yml /home/$NEWUSERNAME/web2.0/communtu-program/config/database.yml
ln -s communtu-program/public/debs/ communtu-packages

# repository of communtu packages and reprepro database
scp -r $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/communtu-program/public/debs/pool /home/$NEWUSERNAME/web2.0/communtu-program/public/debs
scp -r $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/communtu-program/public/debs/dists /home/$NEWUSERNAME/web2.0/communtu-program/public/debs
scp -r $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/communtu-program/debs/db /home/$NEWUSERNAME/web2.0/communtu-program/debs
scp $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/communtu-program/debs/distributions /home/$NEWUSERNAME/web2.0/communtu-program/debs
scp -r $OLDUSERNAME@$OLDSERVER:/home/communtu/web2.0/communtu-program/debs/repos /home/$NEWUSERNAME/web2.0/communtu-program/debs

# keys
scp $OLDUSERNAME@$OLDSERVER:"/home/$OLDUSERNAME/.ssh/*" /home/$NEWUSERNAME/.ssh/

sudo sh -c "ssh $OLDUSERNAME@$OLDSERVER \"sudo cat /root/.ssh/id_rsa\" > /root/.ssh/id_rsa"
sudo sh -c "ssh $OLDUSERNAME@$OLDSERVER \"sudo cat /root/.ssh/id_rsa.pub\" > /root/.ssh/id_rsa.pub"
scp $OLDUSERNAME@$OLDSERVER:"/home/$OLDUSERNAME/.gnupg/*" /home/$NEWUSERNAME/.gnupg/

# old log files
scp -r $OLDUSERNAME@$OLDSERVER:~/web2.0/communtu-program/$OLDUSERNAME/log /home/$NEWUSERNAME/web2.0/communtu-program/log/oldlog

# folder for temporary images
sudo mkdir /local/isos/tmp
sudo chown communtu /local/isos/tmp

# rails server init script
sudo cp script/rails /etc/init.d/
sudo update-rc.d rails defaults

# start rails apps
/home/$NEWUSERNAME/web2.0/communtu-program/script/web start

# security updates
sudo cp /home/$NEWUSERNAME/web2.0/communtu-program/script/security-updates /etc/cron.daily

########################## TODO MANUALLY ############################
#sudoers
sudo cp script/sudoers/* /usr/bin/
# check whether this works or visudo needs to be used
sudo sh -c "cat script/visudo >> /etc/sudoers"

## add the following to user's crontab
0       5       *       *       *       /home/communtu/web2.0/communtu-program/script/nightly-cron
*       *       *       *       *       /home/communtu/web2.0/communtu-program/script/livecd-daemon-check
## add the following to root's crontab
0      4       *       *       1       /sbin/reboot

# check that you can log in from backup server to communtu server
