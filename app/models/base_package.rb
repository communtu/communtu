class BasePackage < ActiveRecord::Base
  has_many :user_packages, :foreign_key => :package_id
  has_many :videos
  
    # type of a package, for sorting package lists
  def ptype
    # first display metapackages
    if self.class == Metapackage then
      return 0
    # then program packages
    elsif self.is_program then
      return 1
    # the library packages etc.  
    else return 2
    end
  end

  def debian_name
    if self.class == Metapackage then
      n="communtu-"+self.name
    else
      n=self.name
    end 
    return debianize_name(n)
  end
  
  def self.debianize_name(n)
    return n.downcase.gsub("ä","ae").gsub("ö","oe").gsub("ü","ue").gsub("ß","ss").gsub(/[^a-z0-9._+-]/, '_')
    # todo: is umlaut elimination really needed?
  end
end
