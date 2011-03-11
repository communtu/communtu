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

# dependencies among Ubuntu packages
# this table contains the transitive closure of the usual "depends" dependencies

# database fields: 
# base_package_id: the needed package
# dep_type: 0 = depends, 1 = recommends, 2 = conflicts, 3 = suggests (see Debian package system)
# package_distr_id: the package in a specific distribution that has the other package as a dependency

class Dependency < ActiveRecord::Base
  belongs_to :package_distr
  belongs_to :base_package
end
