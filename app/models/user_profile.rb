# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# software selection made by the user

# database fields: 
# category_id
# rating
# user_id

class UserProfile < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :category

end
