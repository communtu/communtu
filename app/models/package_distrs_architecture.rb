# join table linking package_distrs and architectures

class PackageDistrsArchitecture < ActiveRecord::Base
  belongs_to :package_distr
  belongs_to :architecture
end
