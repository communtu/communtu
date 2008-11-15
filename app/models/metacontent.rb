class Metacontent < ActiveRecord::Base

    belongs_to :metapackage
    belongs_to :base_package
    has_many :metacontents_distrs
    has_many :distributions, :through => :metacontents_distrs
    has_many :metacontents_derivatives
    has_many :derivatives, :through => :metacontents_derivatives
    def package
        self.base_package
    end

end
