# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# join table linking package_distrs and architectures

# database fields: 
# architecture_id
# outdated: flag used during repository synchronisation
# package_distr_id

class PackageDistrsArchitecture < ActiveRecord::Base
  belongs_to :package_distr
  belongs_to :architecture
end
