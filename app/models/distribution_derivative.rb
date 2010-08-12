# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

class DistributionDerivative < ActiveRecord::Base
  belongs_to :distribution
  belongs_to :derivative
end
