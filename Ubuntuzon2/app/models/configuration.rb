class Configuration < ActiveRecord::Base
  belongs_to :account
  belongs_to :package
  validates_presence_of :account_id, :package_id
  
end
