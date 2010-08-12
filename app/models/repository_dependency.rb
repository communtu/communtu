# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# dependencies among repositories
# e.g. some packages in Ubuntu partner depend on packages in Ubuntu multiverse
# therefore, if Ubuntu partner is added to source.list, we will add
# Ubuntu multiverse as well

class RepositoryDependency < ActiveRecord::Base
  belongs_to :repository, :foreign_key => :depends_on_id
end
