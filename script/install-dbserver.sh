#!/bin/bash
# script for installing communtu database server

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


#TODO: distinguish between installing and moving a webserver

OLDDBUSER=root
OLDDBPASSWORD=test
NEWDBUSER=root
NEWDBPASSWORD=test
OLDSERVER=communtu.org
OLDUSERNAME=communtu
NEWUSERNAME=communtu

# mysql server
sudo apt-get install mysql-server libmysql-ruby ruby1.8-dev libmysqlclient15-dev
sudo scp $OLDUSERNAME@$OLDSERVER:/etc/mysql/my.cnf /etc/mysql/my.cnf
sudo /etc/init.d/mysql reload
mysqladmin -u $NEWDBUSER --password=$NEWDBPASSWORD create communtu
ssh $OLDUSERNAME@$OLDSERVER "mysqldump -u $OLDDBUSER --passwod=$OLDDBPASSWORD --lock-all-tables --add-drop-table communtu | gzip -c > /home/communtu/web2.0/db.backup.gz"
scp $OLDUSERNAME@$OLDSERVER:/home/$OLDUSERNAME/web2.0/db.backup.gz /home/$NEWUSERNAME/web2.0/communtu/
gunzip -c /home/$NEWUSERNAME/web2.0/communtu/db.backup.gz | mysql -u $NEWDBUSER --password=$NEWDBPASSWORD communtu
