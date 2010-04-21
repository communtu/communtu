# Comments to bundles and other things

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
