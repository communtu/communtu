# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

class Conflict < ActiveRecord::Base
  belongs_to :base_package, :foreign_key => :package2_id
end
