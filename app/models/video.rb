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

# videos describing packages

# database fields: 
# base_package_id
# description: deprecated
# description_tid: internationalised description (using table Translation)
# url: deprecated
# url_tid: internationalised url of the video (using table Translation)

class Video < ActiveRecord::Base
   require "lib/utils.rb"
  belongs_to :base_package

  def description
    translation(self.description_tid)
  end

  def url
    trans = translation(self.url_tid)
    if trans == "unknown"
      trans = ""
    end
    return trans
  end
end
