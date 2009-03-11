#!/bin/bash
# script for installing communtu on a new server
OLDSERVER=bremer-commune.dyndns.org
SVNSERVER=bremer-commune.dyndns.org
# apache
sudo apt-get install apache2
scp -r commune@$OLDSERVER:/etc/apache2/* /etc/apache2/ 
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
sudo gem install rails -y 
cd ..
# debian packaging
sudo apt-get install reprepro fakeroot dpkg-dev dh-make 
# mysql server
sudo apt-get install mysql-server libmysql-ruby ruby1.8-dev libmysqlclient15-dev
sudo gem install mysql
mysqladmin -u root -p create communtu
scp commune@$OLDSERVER:/etc/mysql/my.cnf /etc/mysql/my.cnf
ssh commune@$OLDSERVER "mysqldump -u root -p communtu | gzip -c" | mysql -u root -p communtu
sudo /etc/init.d/mysql reload
# checkout rails project
mkdir web2.0
cd web2.0
svn co http://$SVNSERVER/svn/communtu-program communtu-program --username commune 
cd ..
scp commune@$OLDSERVER:/home/commune/web2.0/communtu-program/config/database.yml /home/commune/web2.0/communtu-program/config/database.yml
# start rails apps
scp commune@$OLDSERVER:/home/commune/rails-start . 
/home/commune/web2.0/communtu-program/script/web start

