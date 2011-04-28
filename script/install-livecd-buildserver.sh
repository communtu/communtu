#!/bin/bash
# script for installing communtu liveCD build system

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


# virtual machine, CD extraction and generation tools
sudo apt-get install -y virtinst kvm kvm-pxe kpartx libdbd-sqlite3-perl genisoimage squashfs-tools python-software-properties 
sudo adduser $USER kvm

# abbreviations for logging into test VM 
echo 'SSH="ssh -p 2221 -o StrictHostKeyChecking=no -o ConnectTimeout=500 root@localhost"' >> ~/.bashrc
echo 'SCP="scp -P 2221 -o StrictHostKeyChecking=no -o ConnectTimeout=500"' >> ~/.bashrc

# install commands with root privileges
script/install-sudoer kill-kvm $USER
script/install-sudoer nicekvm $USER

# future code neeeded for the generation of kvm images
# sudo mkdir /remaster
# script/install-sudoer create-mount-image $USER
# script/install-sudoer umount-image $USER
