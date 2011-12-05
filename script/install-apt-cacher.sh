#!/bin/bash
# script for installing apt-cacher

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

# fix apt-cacher bug, see https://bugs.launchpad.net/ubuntu/+source/apt-cacher/+bug/83987
sudo add-apt-repository ppa:aperomsik/aap-ppa
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y apt-cacher
sudo /etc/init.d/apt-cacher restart

# todo: make script/sudoers/clear-apt-proxy-cache-communtu work for apt-cache server different from websever
