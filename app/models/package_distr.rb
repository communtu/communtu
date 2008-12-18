class PackageDistr < ActiveRecord::Base
  belongs_to :package
  belongs_to :repository
  belongs_to :distribution
end
