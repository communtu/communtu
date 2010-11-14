# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# join table recording for each repository the available architectures

# database fields: 
# architecture_id
# repository_id

class RepositoriesArchitecture < ActiveRecord::Base
  belongs_to :repository
  belongs_to :architecture
end
