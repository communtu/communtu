class BasePackage < ActiveRecord::Base
  has_many :user_packages, :foreign_key => :package_id
end
