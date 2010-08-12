# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# dependencies among Ubuntu packages
# this table contains the transitive closure of the usual "depends" dependencies

class Dependency < ActiveRecord::Base
  belongs_to :package_distr
  belongs_to :base_package
end
