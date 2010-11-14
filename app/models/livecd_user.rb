# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# join table providing the list of users of a liveCD

# database fields: 
# livecd_id
# user_id

class LivecdUser < ActiveRecord::Base
  belongs_to :livecd
  belongs_to :user
end
