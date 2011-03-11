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

# Debian tags, see http://debtags.alioth.debian.org/

# FIXME Known bugs:
# There are tags that are equal to facets.
# The Tag model currently defines :name as unique and if we change this, it
# might break everything.

# database fields: 
# description
# is_facet
# name
# nature
# status

class Tag < ActiveRecord::Base
  has_many :package_tags
  has_many :packages, :through => :package_tags

  validates_presence_of :name
  validates_uniqueness_of :name
end
