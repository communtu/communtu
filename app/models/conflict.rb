# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# conflicts between Ubuntu packages
# (direct conflicts as specified by the repository,
#  as well as indirect conflicts, via dependencies)
# currently not used

# database fields: 
# package_id
# package2_id

class Conflict < ActiveRecord::Base
  belongs_to :base_package, :foreign_key => :package2_id
end
