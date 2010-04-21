# join table specifying for which distributions the membership
# of a particular package in a bundle holds

class MetacontentsDistr < ActiveRecord::Base
  belongs_to :metacontent
  belongs_to :distribution
end
