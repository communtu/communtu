# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# Comments to bundles and other things

# database fields: 
# comment
# comment_tid
# metapackage_id
# user_id

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
