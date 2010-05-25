# Ubuntu distributions like Karmic or Lucid
# Communtu allows the contents of bundles to depend on the distribution

class Distribution < ActiveRecord::Base
  require "lib/utils.rb"
  has_many :repositories, :dependent => :destroy
  has_many :metacontents_distrs, :dependent => :destroy
  has_many :debs, :dependent => :destroy
  has_many :package_distrs, :dependent => :destroy
  belongs_to :distribution # predecessor
  has_many :livecds, :dependent => :destroy

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
    RAILS_ROOT + "/debs/repos/" + self.short_name
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
  
  protected
  def after_create
    # generate new configuration file for reprepro
    Deb.write_conf_distributions
    # make folder for package info
    system "mkdir -p #{self.dir_name}"
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
