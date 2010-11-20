# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

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
