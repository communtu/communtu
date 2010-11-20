# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# join table linking packages and tags (debtags)
# the structure should probably changed such that packages are linked with factes and tags

# database fields: 
# package_id
# tag_id

class PackageTag < ActiveRecord::Base
  belongs_to :package
  belongs_to :tag

  validates_presence_of :package_id
  validates_presence_of :tag_id
end
