# (c) 2008-2011 byllgemeinbildung e.V., Bremen, Germany
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

# join table linking packages and tags (debtags)
# the structure should probably changed such that packages are linked with factes and tags

# database fields: 
# package_id
# tag_id

class PackageTag < ActiveRecord::Base
  belongs_to :package
  belongs_to :tag

  validates_presence_of :package_id
  validates_presence_of :tag_id
end
