class Umfrage < ActiveRecord::Base
  has_many :umfrage_packages, :dependent => :destroy
  has_many :umfrage_sources, :dependent => :destroy

  def self.print_all
    Umfrage.find(:all).each{|u| puts "--------------"; puts "---Quellen:"; u.umfrage_sources.each{|s| puts s.source}; puts "---Pakete:"; u.umfrage_packages.each{|p| puts p.package} }
  end
end
