class Repository < ActiveRecord::Base
  has_many :packages, :dependent => :destroy
  belongs_to :distribution
  has_many :package_distrs
  validates_presence_of :license_type, :url, :distribution_id
end
