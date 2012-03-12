class Rating < ActiveRecord::Base
  belongs_to :rate
  belongs_to :rateable, :polymorphic => true
  
  validates_uniqueness_of :user_id, :scope => [:rateable_id, :rateable_type]
end
