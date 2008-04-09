require 'open-uri'
require 'zlib'

class Package < BasePackage

  include PackagesHelper
  belongs_to :distribution
  belongs_to :repository
  
  validates_presence_of :name, :version
  
  
  def self.license_types
    license_types = [ "OpenSource", "Commercial" ]
  end
  
  def self.security_types
    security_types  = [ "Native", "Trusted", "Third-Party" ]
  end
 
  def self.find_packages(search, group, page, distribution)
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
      url = parts[1] + "dists/" + parts[2] + "/" + parts[3] + "/binary-i386/Packages.gz"
    end    
    url
  end
  
  def self.import_source repository
    url  = get_url_from_source (repository.url + " " + repository.subtype)
    packages = packages_to_hash url
    distribution_id = repository.distribution_id
    
    info = { "package_count" => packages.size, "update_count" => 0, "new_count" => 0,\
      "failed" => [], "url" => url }
      
    packages.each do |key,package|
 
      if not package["Description"].nil?
        package["Description"] = package["Description"].gsub(/ . /, "<br/>")
      else
        package["Description"] = ""
      end
      
      res = Package.find(:first, :conditions => ["name=? AND version=? AND distribution_id=?",\
        key, package["Version"], distribution_id])
 
      if res.nil?
        
        res= Package.new ({ :name => key, :version => package["Version"],\
          :distribution_id => distribution_id, :description => package["Description"],\
          :section => package["Section"],\
          :repository_id => repository.id})
          
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
  
    return info
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
    option == "Version" or option == "Description" or option == "Section"
  end
  
end
