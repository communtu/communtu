class Rating < ActiveRecord::Base
  belongs_to :rateable, :polymorphic => true
  
  # NOTE: Comments belong to a user
  belongs_to :user
  belongs_to :metapackage, :foreign_key => :rateable_id, :counter_cache => true
  
  validates_presence_of :comment
  
  # Helper class method to lookup all ratings assigned
  # to all rateable types for a given user.
  def self.find_ratings_by_user(user)
    find(:all,
      :conditions => ["user_id = ?", user.id],
      :order => "created_at DESC"
    )
  end
end