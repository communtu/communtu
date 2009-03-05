class Package < ActiveRecord::Base
  has_many :configurations
  has_many :comments
  acts_as_rateable
  
end
