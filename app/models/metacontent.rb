class Metacontent < ActiveRecord::Base

    belongs_to :metapackage
    belongs_to :base_package

    def package
        self.base_package
    end

end
