# table recording the permissions for each user

class Permission < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
end