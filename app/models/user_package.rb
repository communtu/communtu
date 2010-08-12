# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

class UserPackage < ActiveRecord::Base
  belongs_to :user
  belongs_to :base_package, :foreign_key => :package_id
  validates_presence_of :user, :base_package
end
