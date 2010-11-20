# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# dependencies among Ubuntu packages
# this table contains the transitive closure of the usual "depends" dependencies

# database fields: 
# base_package_id: the needed package
# dep_type: 0 = depends, 1 = recommends, 2 = conflicts, 3 = suggests (see Debian package system)
# package_distr_id: the package in a specific distribution that has the other package as a dependency

class Dependency < ActiveRecord::Base
  belongs_to :package_distr
  belongs_to :base_package
end
