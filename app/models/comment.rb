class Comment < ActiveRecord::Base
  belongs_to :meta_package
  belongs_to :user
  
  validates_presence_of :comment
  validates_presence_of :user_id
end
