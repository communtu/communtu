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

# join table linking bundles with the packages and bundles they contain

# database fields: 
# base_package_id: id of package or bundle that is contained in the bundle
# metapackage_id: bundle

class Metacontent < ActiveRecord::Base

    belongs_to :metapackage
    belongs_to :base_package
#    belongs_to :package, :foreign_key => :base_package_id
    has_many :metacontents_distrs, :dependent => :destroy
    has_many :distributions, :through => :metacontents_distrs
    has_many :metacontents_derivatives, :dependent => :destroy
    has_many :derivatives, :through => :metacontents_derivatives
    def package
        self.base_package
    end

end
