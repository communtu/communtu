# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

class UserProfile < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :category

end
