class Metacontent < ActiveRecord::Base
#  belongs_to :metapackage
    belongs_to :package, :foreign_key =>  :package_id 
    belongs_to :metapackage, :foreign_key =>  :metapackage_id

    def abstract_package
        if not is_meta
            return Package.find(package_id)
        else
            return Metapackage.find(metapackage_id)
        end
    end

end
