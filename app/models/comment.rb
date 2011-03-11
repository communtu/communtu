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

# Comments to bundles and other things

# database fields: 
# comment: comment string (deprecated)
# comment_tid: internationalised comment string (via table Translation)
# metapackage_id: bundle that is being commented
# user_id: creator of the comment

class Comment < ActiveRecord::Base
#  require "lib/utils.rb"
  belongs_to :meta_package
  belongs_to :user
  
  validates_presence_of :comment
  validates_presence_of :user_id
  def comment
    trans = translation(self.comment_tid)
    if trans == "unknown"
      trans = ""
    end
    return trans
  end
end
