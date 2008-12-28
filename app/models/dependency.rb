class Dependency < ActiveRecord::Base
  belongs_to :package_distr
  belongs_to :base_package
end
