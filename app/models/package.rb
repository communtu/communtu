require 'open-uri'
require 'zlib'

class Package < BasePackage

  include PackagesHelper
  belongs_to :distribution
  belongs_to :repository
  has_many :dependencies, :foreign_key => :base_meta_package_id
  has_many :depends, :through => :dependencies, :source => :base_package, \
    :conditions => 'dependencies.dep_type = 0'    
  has_many :recommends, :through => :dependencies, :source => :base_package, \
    :conditions => 'dependencies.dep_type = 1'
  has_many :depends_or_recommends, :through => :dependencies, :source => :base_package, \
    :conditions => 'dependencies.dep_type <= 1'
  has_many :conflicts, :through => :dependencies, :source => :base_package, \
    :conditions => 'dependencies.dep_type = 2'
  validates_presence_of :name, :version
  
  def assign_depends list
    list.each do |p|
      Dependency.create(:base_meta_package_id => id, :base_package_id => p.id, :dep_type => 0)
    end
  end

  def assign_recommends list
    list.each do |p|
      Dependency.create(:base_meta_package_id => id, :base_package_id => p.id, :dep_type => 1)
    end
  end

  def assign_conflicts list
    list.each do |p|
      Dependency.create(:base_meta_package_id => id, :base_package_id => p.id, :dep_type => 2)
    end
  end

  def self.license_types
    license_types = [ "OpenSource", "Commercial" ]
  end
  
  def self.security_types
    security_types  = [ "Native", "Trusted", "Third-Party" ]
  end
 
  def self.find_packages(search, group, page, distribution)
  
    if distribution.nil?
        return []
    end
  
    if not search.nil?
          packages = Package.find(:all, :page => {:size => 10, :current => page},
            :conditions => ["distribution_id = ? AND name like ?", distribution.id, "%" + search + "%"], :order => "name")
    else
        if group.nil? or group == "all"
          packages = Package.find(:all, :page => {:size => 10, :current => page},
            :conditions => ["distribution_id = ?", distribution.id], :order => "name")
        else
          packages = Package.find(:all, :page => {:size => 10, :current => page},
            :conditions => ["distribution_id = ? and section = ?", distribution.id, group], :order => "name")
        end
    end
  end
  
  def self.get_url_from_source source
    parts = source.split " "
    if parts.length == 4
      # add trailing "/" if necessary
      if parts[1][-1] != 47 then
        parts[1] += "/"
      end
      url = parts[1] + "dists/" + parts[2] + "/" + parts[3] + "/binary-i386/Packages.gz"
    end    
    url
  end
  
  def self.import_source repository
    url  = get_url_from_source(repository.url + " " + repository.subtype)
    packages = packages_to_hash url
    distribution_id = repository.distribution_id
    
    if packages.nil? then
      return nil
    end
    
    info = { "package_count" => packages.size, "update_count" => 0, "new_count" => 0,\
      "failed" => [], "url" => url }

    # enter packages
    packages.each do |key,package|
 
      if not package["Description"].nil?
        package["Description"] = package["Description"].gsub(/ . /, "<br/>")
      else
        package["Description"] = ""
      end
      
      res = Package.find(:first, :conditions => ["name=? AND version=? AND distribution_id=?",\
        key, package["Version"], distribution_id])
 
      if res.nil?
        
        res= Package.new({ :name => key, :version => package["Version"],\
          :distribution_id => distribution_id, :description => package["Description"],\
          :fullsection => package["Section"],\
          # für :section nur den letzten Teil verwenden
          :section => package["Section"].split("/")[-1],\
          :filename => package["Filename"],\
          :repository_id => repository.id,
          :license_type => repository.license_type})
          
        if res.save
          info["new_count"] = info["new_count"].next 
        else
          info["failed"].push key
        end
        
      else
        if res.update_attributes({ :name => key, :version => package["Version"], :description => package["Description"], :section => package["Section"]})
            
          info["update_count"] = info["update_count"].next
        else
          info["failed"].push key
        end
      end
    end

    # enter dependency info
    packages.each do |key,package|
      p = Package.find(:first, :conditions => ["name=? AND version=? AND distribution_id=?",\
             key, package["Version"], distribution_id])
      if not p.nil?
        p.dependencies.delete_all
        p.assign_depends(parse_dependencies(package["Depends"],distribution_id))
        p.assign_recommends(parse_dependencies(package["Recommends"],distribution_id))
        p.assign_conflicts(parse_dependencies(package["Conflicts"],distribution_id))
      end    
    end
  
    return info
  end

  def self.parse_dependencies(s,distribution)
    if s.nil? then
      return []
    else
      s.split(",").map{|s1| s1.split (" (").first.lstrip}.map{ |name|
        Package.find(:first, :conditions => ["name=? AND distribution_id=?",\
               name, distribution]) }.compact
    end
  end

private
  def self.packages_to_hash url
    file = open(url, 'User-Agent' => 'Ruby-Wget')
    
    packages = {}
    reader   = Zlib::GzipReader.new(file)

    while line = reader.readline do
        if not line.sub!(/^Package: /, "").nil?
            package = line.chomp
            packages.store package, {}
            readpackage = lambda do |content|
                line = reader.readline
                if (not line == "\n")
                    if (line.match(/^ /).nil?)
                        option  = line.match(/^.*: /)[0].chop.chop
                        content = line.gsub(option+": ", "").strip.chomp
                        
                        if is_valid_option? option
                            packages[package].store option, content
                        end
                    else
                        content << line
                    end
                    readpackage.call content
                end
            end
            readpackage.call nil
        else
           # error
        end
    end
    ensure
        return packages 
  end
  
  def self.is_valid_option? option
    option == "Version" or option == "Description" or option == "Section" \
     or option == "Depends" or option == "Recommends" \
     or option == "Conflicts" or option == "Filename"
  end
  
end
