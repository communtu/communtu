# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# packages that are installed in a plain standard installation
# (this varies depending on distribution, derivative and architecture)

class StandardPackage < ActiveRecord::Base
  belongs_to :package
  belongs_to :distribution
  belongs_to :derivative
  belongs_to :architecture
end
