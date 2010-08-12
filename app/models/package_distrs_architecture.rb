# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# join table linking package_distrs and architectures

class PackageDistrsArchitecture < ActiveRecord::Base
  belongs_to :package_distr
  belongs_to :architecture
end
