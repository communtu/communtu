#!/bin/bash
# script for installing communtu on a new server
# Es muss noch nach dem Script die Datei /etc/apache2/sites-enabled/all angepasst werden.
# Weiter muss in der Apache-Config /etc/apache2/apache2.conf hoechstwahrscheinlich das Root-Verzeichnis
# auskommentiert werden.
OLDSERVER=bremer-commune.dyndns.org
SVNSERVER=bremer-commune.dyndns.org
# folder for web projects
mkdir web2.0
# apache und mail
sudo apt-get install apache2
#scp -r commune@$OLDSERVER:/etc/apache2/* /etc/apache2/ 
sudo apt-get install php5 libapache2-mod-python sendmail
sudo a2enmod proxy
sudo /etc/init.d/apache2 restart
# subversion
sudo apt-get install subversion libapache2-svn
# rails
sudo apt-get install ruby rdoc irb libyaml-ruby libzlib-ruby ri libopenssl-ruby sqlite3 libsqlite3-ruby
wget http://rubyforge.org/frs/download.php/29548/rubygems-1.0.1.tgz 
tar xzvf rubygems-1.0.1.tgz
cd rubygems-1.0.1
sudo ruby setup.rb
sudo ln -s /usr/bin/gem1.8 /usr/bin/gem
sudo gem update --system
sudo gem install -v=2.1.0 rails -y 
cd ..
# debian packaging
sudo apt-get install reprepro fakeroot dpkg-dev dh-make build-essential debootstrap schroot
#backup
sudo apt-get install rsync
# mysql server
sudo apt-get install mysql-server libmysql-ruby ruby1.8-dev libmysqlclient15-dev
sudo gem install mysql
mysqladmin -u root -p create communtu
scp commune@$OLDSERVER:/etc/mysql/my.cnf /etc/mysql/my.cnf
ssh commune@$OLDSERVER "mysqldump -u root -p communtu | gzip -c > /home/commune/web2.0/communtu-program/db.dump.gz"
scp commune@$OLDSERVER:/home/commune/web2.0/communtu-program/db.dump.gz /home/commune/web2.0/communtu-program/
gunzip -c /home/commune/web2.0/communtu-program/db.dump.gz | mysql -u root -p communtu
sudo /etc/init.d/mysql reload
# checkout rails project
cd web2.0
svn co http://$SVNSERVER/svn/communtu-program communtu-program --username commune 
cd ..
scp commune@$OLDSERVER:/home/commune/web2.0/communtu-program/config/database.yml /home/commune/web2.0/communtu-program/config/database.yml
ln -s communtu-program/public/debs/ communtu-packages
# start rails apps
scp commune@$OLDSERVER:/home/commune/rails-start . 
/home/commune/web2.0/communtu-program/script/web start

