class RepositoryDependency < ActiveRecord::Base
  belongs_to :repository, :foreign_key => :depends_on_id
end
