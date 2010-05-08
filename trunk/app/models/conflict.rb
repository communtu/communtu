class Conflict < ActiveRecord::Base
  belongs_to :base_package, :foreign_key => :package2_id
end
