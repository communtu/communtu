# (c) 2008-2011 by Allgemeinbildung e.V., Bremen, Germany
# This file is part of Communtu.

# Communtu is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Communtu is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero Public License for more details.

# You should have received a copy of the GNU Affero Public License
# along with Communtu.  If not, see <http://www.gnu.org/licenses/>.

# Ubuntu distributions like Karmic or Lucid
# Communtu allows the contents of bundles to depend on the distribution

# database fields: 
# description: deprecated
# description_tid: internationalised description, using table Translation
# distribution_id: predecessor distribution
# invisible: distributions should be marked invisible during setup of a new distribution
# name: full name, like Lucid Lynx 10.04
# preliminary: distributions should be marked preliminary if they have not been officially released yet 
# short_name: abbreviated name, like Lucid
# url: deprecated
# url_tid: internationalised link to further info, using table Translation

class Distribution < ActiveRecord::Base
  require "lib/utils.rb"
  has_many :repositories, :dependent => :destroy
  has_many :metacontents_distrs, :dependent => :destroy
  has_many :debs, :dependent => :destroy
  has_many :package_distrs, :dependent => :destroy
  belongs_to :distribution # predecessor
  has_many :livecds, :dependent => :destroy
  has_many :distribution_derivatives, :dependent => :destroy
  has_many :derivatives, :through => :distribution_derivatives

  DEFAULT_DISTRO_NAME = "Lucid"

  def predecessor
    self.distribution
  end

  def successor
    Distribution.find_by_distribution_id(self.id)
  end
  
  def description
    translation(self.description_tid)
  end

  def url
    translation(self.url_tid)
  end

  # folder for storing repository information
  def dir_name
    Rails.root.to_s + "/debs/repos/" + self.short_name
  end

  # package files in the communtu repository
  def package_files(arch)
    "#{Rails.root.to_s}/public/debs/dists/ubuntu-#{self.short_name.downcase}-all-all/*/binary-#{arch.name}/Packages"
  end
  
  # most recent stable distribution
  def self.current
    Distribution.find(:first,:conditions=>{:invisible=>false,:preliminary=>false},:order=>"id DESC")
  end
  
  # extract distribution from browser info string
  def self.browser_distribution(s)
    if s.nil? then
      return nil
    end
    s1 = s.downcase
    Distribution.all.each do |d|
      if !s1.index(d.short_name.downcase).nil? then
        return d
      end
    end
    return nil
  end

  # extract distribution from browser info string, use default if nothing can be extracted
  def self.browser_distribution_with_default(s)
    d = Distribution.browser_distribution(s)
    if d.nil? then
      return Distribution.find_by_short_name(DEFAULT_DISTRO_NAME)
    else
      return d
    end
  end

  # extract distribution name from browser info string
  def self.browser_info(s)
    d = Distribution.browser_distribution(s)
    if d.nil? then
      return ""
    else
      return d.name
    end
  end
  
  def test_all_repos
    self.repositories.map { |r| r.test_sources}.flatten
  end
  
  protected
  def after_create
    # register distribution for all derivatives
    Derivative.all.each do |der|
      der.distributions << self
    end  
    # generate new configuration file for reprepro
    Deb.write_conf_distributions
    # make folder for package info
    system "mkdir -p #{self.dir_name}"
  end

  def before_destroy
    pre = self.predecessor
    suc = self.successor
    # are we going to remove some intermediate distribution?
    if !pre.nil? and !suc.nil? then
      # then create a bridge
      suc.distribution = pre
      suc.save
    end
  end

  def after_destroy
    # generate new configuration file for reprepro
    Deb.write_conf_distributions
    # remove debian packages
    Deb.clearvanished
    # remove package info
    system "rm -r #{self.dir_name}"
  end
end
