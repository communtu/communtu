class Distribution < ActiveRecord::Base
  require "lib/utils.rb"
  has_many :repositories, :dependent => :destroy
  has_many :metacontents_distrs, :dependent => :destroy
  has_many :debs, :dependent => :destroy  

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

  # return the distribution info from the browser info string
  def self.browser_info(s)
    if s.nil? then
      return nil
    end
    index = s.index("Ubuntu")
    if index.nil? then
      s = nil
    else
      s = s[index+7,s.length]
      index = s.index(")")
      if !index.nil? then
        s = s[0,index+1]
      end  
    end  
    return s
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
