class Group < ActiveRecord::Base
  has_many :groupings
  has_many :users, :through => :groupings
  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  has_many :metapackages, :foreign_key => :group_id
  validates_uniqueness_of :name
end
