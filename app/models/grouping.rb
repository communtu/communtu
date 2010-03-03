class Grouping < ActiveRecord::Base
  belongs_to :group
  belongs_to :user
  
  validates_uniqueness_of :group_id, :scope => :user_id
end
