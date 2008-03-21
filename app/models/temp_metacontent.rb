class TempMetacontent < ActiveRecord::Base
  belongs_to :temp_metapackage, :foreign_key => :temp_metapackage_id
  belongs_to :package;
end
