class StandardPackage < ActiveRecord::Base
  belongs_to :package
  belongs_to :distribution
  belongs_to :derivative
  belongs_to :architecture
end
