class Category < ActiveRecord::Base
  has_many :bundles
end
