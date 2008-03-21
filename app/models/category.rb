class Category < ActiveRecord::Base
  acts_as_tree :order => "name"
  has_many :metapackages
  
end
