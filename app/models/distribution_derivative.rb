# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# table recording which distributions are available for a derivative
# e.g. for Lubuntu, only Lucid is available

class DistributionDerivative < ActiveRecord::Base
  belongs_to :distribution
  belongs_to :derivative
end
