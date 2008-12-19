class Umfrage < ActiveRecord::Base
  has_many :umfrage_packages, :dependent => :destroy
  has_many :umfrage_sources, :dependent => :destroy
end
