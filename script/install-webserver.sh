#!/bin/bash
# script for installing communtu web server

# (c) 2008-2011 by Allgemeinbildung e.V., Bremen, Germany
# This file is part of Communtu.

# Communtu is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Communtu is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero Public License for more details.

# You should have received a copy of the GNU Affero Public License
# along with Communtu.  If not, see <http://www.gnu.org/licenses/>.

OLDDBUSER=root
OLDDBPASSWORD=test
NEWDBUSER=root
NEWDBPASSWORD=test
OLDSERVER=communtu.org
OLDUSERNAME=communtu
NEWUSERNAME=communtu
# folder for web projects
cd
mkdir web2.0

# apache und mail
sudo apt-get install -y apache2 webalizer
mkdir -p webalizer/en-communtu
mkdir -p webalizer/de-communtu
mkdir -p webalizer/fr-communtu
mkdir -p webalizer/pack-communtu

sudo scp $OLDUSERNAME@$OLDSERVER:/etc/apache2/sites-available/communtu.conf /etc/apache2/sites-available/
sudo a2ensite communtu.conf
sudo apt-get install -y php5 libapache2-mod-python sendmail
sudo a2enmod proxy

# git
sudo apt-get install -y git-core 
sudo /etc/init.d/apache2 restart

# rails
sudo apt-get install -y ruby rdoc irb libyaml-ruby libzlib-ruby ri libopenssl-ruby sqlite3 libsqlite3-ruby rubygems mongrel libvirt-ruby
sudo ln -s /usr/bin/gem1.8 /usr/bin/gem
sudo ln -s /var/lib/gems/1.8/bin/rake /usr/bin/
sudo gem update --system
sudo gem install -v=2.2.2 rails -y
sudo gem install i18n
# needed for backgroundrb
sudo gem install chronic packet

# debian packaging
sudo apt-get install -y reprepro fakeroot dpkg-dev dh-make build-essential debootstrap schroot edos-debcheck apt-mirror

#backup
sudo apt-get install -y rsync

#Editor Console
sudo apt-get install -y joe

# checkout rails project
cd web2.0
git clone git://github.com/communtu/communtu.git
# developers should use
# git clone git@github.com:communtu/communtu.git
echo 3002 > communtu/config/ports
echo 3003 >> communtu/config/ports
echo 3004 >> communtu/config/ports
echo 3005 >> communtu/config/ports
echo 3006 >> communtu/config/ports
cp communtu/config/database.yml.template communtu/config/database.yml
# database user and password
sed -i 's/root/$NEWDBUSER/' communtu/config/database.yml
sed -i 's/password: /password: $NEWDBPASSWORD/' communtu/config/database.yml
# test system
cp -r communtu communtu-test
echo 3020 > communtu-test/config/ports
sed -i 's/database: communtu/database: communtu-test/' communtu-test/config/database.yml
mysqladmin -u $NEWDBUSER --password=$NEWDBPASSWORD create communtu-test
cd ..
# database configuration
scp $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/communtu/config/database.yml /home/$NEWUSERNAME/web2.0/communtu/config/database.yml
ln -s communtu/public/debs/ communtu-packages

# repository of communtu packages and reprepro database
scp -r $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/communtu/public/debs/pool /home/$NEWUSERNAME/web2.0/communtu/public/debs
scp -r $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/communtu/public/debs/dists /home/$NEWUSERNAME/web2.0/communtu/public/debs
scp -r $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/communtu/debs/db /home/$NEWUSERNAME/web2.0/communtu/debs
scp $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/communtu/debs/distributions /home/$NEWUSERNAME/web2.0/communtu/debs
scp -r $OLDUSERNAME@$OLDSERVER:/home/communtu/web2.0/communtu/debs/repos /home/$NEWUSERNAME/web2.0/communtu/debs

# keys
scp $OLDUSERNAME@$OLDSERVER:"/home/$OLDUSERNAME/.ssh/*" /home/$NEWUSERNAME/.ssh/

sudo sh -c "ssh $OLDUSERNAME@$OLDSERVER \"sudo cat /root/.ssh/id_rsa\" > /root/.ssh/id_rsa"
sudo sh -c "ssh $OLDUSERNAME@$OLDSERVER \"sudo cat /root/.ssh/id_rsa.pub\" > /root/.ssh/id_rsa.pub"
scp $OLDUSERNAME@$OLDSERVER:"/home/$OLDUSERNAME/.gnupg/*" /home/$NEWUSERNAME/.gnupg/

# old log files
scp -r $OLDUSERNAME@$OLDSERVER:~/web2.0/communtu/$OLDUSERNAME/log /home/$NEWUSERNAME/web2.0/communtu/log/oldlog

# rails server init script
sudo cp script/rails /etc/init.d/
sudo update-rc.d rails defaults

# write distribution confs
rake db:repo:distributions

# start rails apps
/home/$NEWUSERNAME/web2.0/communtu/script/web start

# security updates
sudo cp /home/$NEWUSERNAME/web2.0/communtu/script/security-updates /etc/cron.daily

# sudoers
script/install-sudoer libvirt-log $USER

## add the following to user's crontab
script/add-to-crontab "0       5       *       *       *       /home/$NEWUSERNAME/web2.0/communtu/script/nightly-cron"
script/add-to-crontab "*       *       *       *       *       /home/$NEWUSERNAME/web2.0/communtu/script/livecd-daemon-check"
script/add-to-crontab "0       2       *       *       *       /home/$NEWUSERNAME/web2.0/communtu/script/livecd-counter"
## add the following to root's crontab
sudo script/add-to-crontab "0      4       *       *       1       /sbin/reboot"

# check that you can log in from backup server to communtu server
