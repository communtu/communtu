# join table specifying for which derivatives the membership
# of a particular package in a bundle holds

class MetacontentsDerivative < ActiveRecord::Base
  belongs_to :metacontents
  belongs_to :derivative
end
