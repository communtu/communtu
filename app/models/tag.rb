# FIXME Known bugs:
# There are tags that are equal to facets.
# The Tag model currently defines :name as unique and if we change this, it
# might break everything.
class Tag < ActiveRecord::Base
  has_many :package_tags
  has_many :packages, :through => :package_tags, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name
end
