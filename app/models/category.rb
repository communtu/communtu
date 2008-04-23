class Category < ActiveRecord::Base
  acts_as_tree :order => "name"
  has_many :metapackages
  belongs_to :category, :foreign_key => 'parent_id'
  
  def parent_name
    if category.nil? then "" else category.name end
  end
end
