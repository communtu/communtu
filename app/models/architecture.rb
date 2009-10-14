class Architecture < ActiveRecord::Base
  has_many :package_distrs_architectures, :dependent => :destroy
end
