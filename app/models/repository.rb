class Repository < ActiveRecord::Base
  belongs_to :distribution
  has_many :package_distrs, :dependent => :destroy
  validates_presence_of :license_type, :url, :distribution_id
end
