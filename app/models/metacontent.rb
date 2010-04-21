# join table linking bundles with the packages they contain

class Metacontent < ActiveRecord::Base

    belongs_to :metapackage
    belongs_to :base_package
#    belongs_to :package, :foreign_key => :base_package_id
    has_many :metacontents_distrs
    has_many :distributions, :through => :metacontents_distrs
    has_many :metacontents_derivatives
    has_many :derivatives, :through => :metacontents_derivatives
    def package
        self.base_package
    end

end
