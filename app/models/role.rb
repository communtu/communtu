# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# roles of users (like admin, power user, ...)

class Role < ActiveRecord::Base
  has_many :permissions
  has_many :users, :through => :permissions
end