class PackageTag < ActiveRecord::Base
  belongs_to :package
  belongs_to :tag

  validates_presence_of :package_id
  validates_presence_of :tag_id
end
