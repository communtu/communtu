class Distribution < ActiveRecord::Base
  has_many :packages, :dependent => :destroy
  has_many :repositories, :dependent => :destroy
  has_many :metapackages, :dependent => :destroy
end
