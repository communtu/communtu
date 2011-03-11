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

# database table for temporarily storing the current selection of
# Ubuntu packages when creating or editing a bundle

# database fields: 
# metapackage_id: link to bundle that is being edited, nil of a new bundle is created
# name: name of bundle

class Cart < ActiveRecord::Base

    has_many :cart_contents, :dependent => :destroy
    has_many :base_packages, :through => :cart_contents
    belongs_to :metapackage

end
