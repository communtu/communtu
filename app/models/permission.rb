# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# table recording the permissions for each user

# database fields: 
# role_id
# user_id

class Permission < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
end