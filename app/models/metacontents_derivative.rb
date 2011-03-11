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

# join table specifying for which derivatives the membership
# of a particular package in a bundle holds

# database fields: 
# derivative_id
# metacontent_id

class MetacontentsDerivative < ActiveRecord::Base
  belongs_to :metacontent
  belongs_to :derivative

  def self.cleanup
    MetacontentsDerivative.all.each do |mcd|
      if mcd.metacontent.nil? or mcd.derivative.nil? then
        puts "Removing dangling MetacontentsDerivative #{mcd.id}"
        mcd.destroy
      end
    end
  end

end
