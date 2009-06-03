require 'open-uri'
require 'zlib'
require 'find'

class Package < BasePackage

  include PackagesHelper
#  belongs_to :distribution
#  belongs_to :repository
  has_many   :comments, :foreign_key => :metapackage_id, :dependent => :destroy
  has_many :metacontents, :foreign_key => :base_package_id
  has_many :metapackages, :through => :metacontents
  has_many :package_distrs, :foreign_key => :package_id
#  has_many :distributions, :through => :package_distrs
  has_many :repositories, :through => :package_distrs
  has_many :distributions, :through => :package_distrs
  validates_presence_of :name

  def repositories_dist(distribution)
    pds = PackageDistr.find(:all,:conditions=>["package_id = ? and distribution_id = ?",self.id,distribution.id])
    return pds.map{|pd| pd.repository}
  end

  def is_present(distribution,licence,security)
#    PackageDistr.find(:all,:conditions=>["package_id = ? and distribution_id = ? and repositories.",self.id,distribution.id], :include => :repository)
    !self.repositories_dist(distribution).select{|r| r.security_type<=security && r.license_type<=licence}.empty?
  end

  def unique_name(distribution)
    name+"-"+distribution.name.split(" ")[0]
  end
  
  def is_meta
    section=="metapackages"
  end

  def is_sub_meta(m)
    repository == m.repository &&
    (self.depends_or_recommends - m.depends_or_recommends).empty? 
  end

  def self.sub_metas
    metas = Package.find(:all, :conditions => ["section = ?","metapackages"])
    submetas = []
    metas.each do |m1|
      metas.each do |m2|
        if m1!=m2 && m1.is_sub_meta(m2) then submetas <<= [m1,m2] end
      end
    end
    return submetas
  end

  # compute a hash of dependencies for a package. per repository
  # join the common dependencies
  def dependencies_intersection
    # fetch the repositories...
    pds = self.package_distrs.clone
    if pds.nil? or pds.empty? then
      return {}
    end
    # arbitrarily start with the first one...
    intersection = yield pds.pop
    pds.each do |pd|
      # ... and then intersect with all the others
      intersection = intersection & (yield pd)
    end
    result = {:all => intersection}
    self.package_distrs.each do |pd|
      result[pd.repository] = (yield pd) - intersection
    end
    return result
  end

  # compute the union of all dependencies
  # mark each package in the dependencies with the repositories
  def dependencies_union
    union = {}
    self.package_distrs.each do |pd|
      (yield pd).each do |p|
        if union[p].nil? then
          union[p] = []
        end
        union[p] << pd.repository
      end
    end
    return union
  end

  # compute all packages that depend on (or recommend) the given one,
  # iny any distribution
  def used_by
    Package.find(:all, :conditions => ["dependencies.base_package_id = ? and dependencies.dep_type <= ?",self.id,1],
                 :include => {:package_distrs, :dependencies})
  end
  
  def conflicts
    c = Set.[]
    self.package_distrs.each do |pd|
      c.merge(pd.conflicts)
    end
    return c
  end

  def stars
    if popcon.nil? then
      nil
    else
      5 * Math.log(popcon>0 ? popcon : 1) / Math.log(Package.maximum(:popcon))
    end
  end

  def self.license_types
    license_types = [ I18n.t(:model_package_0), I18n.t(:model_package_1) ]
  end

  def self.show_license_type(t)
    if t.nil? then I18n.t(:model_package_2) else license_types[t] end
  end

  def self.security_types
    security_types  = [ I18n.t(:model_package_3), I18n.t(:model_package_4), I18n.t(:model_package_5) ]
  end

  def installedsize(dist)
    pd = PackageDistr.find(:first,:conditions => {:package_id => self.id, :distribution_id => dist.id})
    if pd.nil? 
      return nil
    else
      return pd.installedsize
    end
  end

  # for debian packaging
  def self.license_components
    license_types = [ "free", "all" ]
  end

  def self.security_components
    security_types  = [ "native", "trusted", "all" ]
  end

  def compute_license_type
    (self.repositories.map{|r| r.license_type} <<0).max
  end
  
  def compute_security_type
    (self.repositories.map{|r| r.security_type} <<0).max
  end
  
  # compute the license type for a bundle as the maximum of licesce types for the list of packages
  def self.meta_license_type(ps)
    ps.map{|p| p.repositories.map{|r| r.license_type}}.flatten.max
  end
    
  def self.find_packages(search, group, only_programs, page)
    cond_str = "1"
    cond_vals = []
    if not search.nil?
        cond_str += " and name like ?"
        cond_vals << "%" + search + "%"
    end    
    if !(group.nil? or group == "all") 
        cond_str += " and section = ?"
        cond_vals << group
    end
    if only_programs then
        cond_str += " and is_program = ?"
        cond_vals << '1'
    end
    Package.find(:all, :page => {:size => 10, :current => page}, \
                       :conditions => ([cond_str]+cond_vals), \
                       :order => "popcon desc, name asc")
  end
  
  def self.get_url_from_source source
    parts = source.split " "
    if parts.length >= 3
      # add trailing "/" if necessary
      if parts[1][-1] != 47 then
        parts[1] += "/"
      end
      # get URL for 32 bit version - this should be changed in the future!
      if parts[3].nil? then
        url = parts[1] + parts[2] + "/Packages.gz"
      else  
        url = parts[1] + "dists/" + parts[2] + "/" + parts[3] + "/binary-i386/Packages.gz"
      end
      return {:url => url}
    else
      return {:error => source+t(:model_package_6)}
    end    
  end
  
  def self.min(x,y)
    if x <= y then x else y end
  end
  
  # test whether a source is present
  def self.test_source repository
    url  = get_url_from_source(repository.name)[:url]
    if url.nil? then return {:error => I18n.t(:model_package_7,{:repo=> repository.url + " " + repository.subtype})} end
    begin
      file = open(url, 'User-Agent' => 'Ruby-Wget')
    rescue  
      return {:error => url}
    else 
      return {}  
    end  
  end

  def self.import_source repository

    distribution_id = repository.distribution_id

    # get URL for repository
    url  = get_url_from_source(repository.name)
    if !url[:error].nil? then
      return url
    end
    url = url[:url]
    # read in all packages from repository
    packages = packages_to_hash url     
    if !packages[:error].nil? then
      return packages
    end
    
    info = { "package_count" => packages.size, "update_count" => 0, "new_count" => 0,\
      "failed" => [], "url" => url }

    # delete packages that are no longer in the repository
    pps = packages[:packages].values
    repository.package_distrs.each do |pd|
      if !pps.include?(pd.package) then
        pd.destroy
      end
    end

    # enter packages
    packages[:packages].each do |name,package|
 
      # adapt description if nil
      if package["Description"].nil?
        package["Description"] = ""
      end

      # compute attributes for package
      attributes_package = { :name => name, 
          :description => package["Description"],\
          :fullsection => package["Section"],\
          # für :section nur den letzten Teil verwenden
          :section => package["Section"].split("/")[-1]}

      # look for existing package
      p = Package.find(:first, :conditions => ["name=?",name])
      if p.nil?
        # no package? create a new one
        p= Package.new(attributes_package)
        if p.save
          info["new_count"] = info["new_count"].next 
        else
          info["failed"].push name
        end
      else
        # package exists, then update attributes
        if p.update_attributes(attributes_package)
          info["update_count"] = info["update_count"].next
        else
          info["failed"].push name
        end
      end

      # compute attributes for package_distr
      attributes_package_distr = {
          :package_id => p.id,
          :version => package["Version"],
          :distribution_id => distribution_id, 
          :filename => package["Filename"],
          :repository_id => repository.id,
          :size => package["Size"], 
          :installedsize => package["Installed-Size"]}

      # compute license type by minimum with existing one
      if p.license_type.nil? then
        p.license_type = repository.license_type
      else 
        p.license_type = min(repository.license_type,p.license_type)
      end

      # compute security type by minimum with existing one
      if p.security_type.nil? then
        p.security_type = repository.security_type
      else 
        p.security_type = min(repository.security_type,p.security_type)
      end   

      # update package_distr
      pd = PackageDistr.find(:first, :conditions => 
             ["package_id = ? and repository_id = ?",p.id,repository.id])
      if pd.nil?
        # no package_distr? create a new one
          pd = PackageDistr.new(attributes_package_distr)
          if !pd.save then
            info["failed"].push(name + " " + repository.url)
          end
      else
        # package exists, then update attributes
          if !pd.update_attributes(attributes_package_distr) then
            info["failed"].push(name + " " + repository.url)
          end
      end         
    end # packages[:packages].each 
    
    # enter dependency info - this must happen *after* creation of the packages!
    packages[:packages].each do |name,package|
      p = Package.find(:first, :conditions => ["name=?",name])
      if not p.nil?
        pd = PackageDistr.find(:first, :conditions => 
           ["package_id = ? and repository_id = ?",p.id,repository.id])
        if not pd.nil?
          pd.dependencies.delete_all
          pd.assign_depends(parse_dependencies(package["Depends"]))
          pd.assign_recommends(parse_dependencies(package["Recommends"]))
          pd.assign_suggests(parse_dependencies(package["Suggests"]))
          pd.assign_conflicts(parse_unversioned_dependencies(package["Conflicts"]))
        else raise I18n.t(:model_package_9)
        end
      else raise I18n.t(:model_package_10)
      end
    end
  
    return info
  end

  # get all dependencies
  def self.parse_dependencies(s)
    if s.nil? then
      return []
    else
      s.split(",").map{|s1| s1.split(" (").first.lstrip}.map{ |name|
        Package.find_by_name(name) }.compact
    end
  end

  # get all dependencies without version
  def self.parse_unversioned_dependencies(s)
    if s.nil? then
      return []
    else
      packages = []
      s.split(",").map{|s1| s1.split(" (")}.each do |p|
        if p.length == 1 then
          packages.push(Package.find_by_name(p.first.lstrip))
        end
      end
      return packages.compact
    end
  end

  
  # display an image in a given size
  def self.show_image(url,size)
      s = size.to_s
      return '<img border="0" height="'+s+'" src="'+url+'"/>'
  end
  
  # display icon for a package, if existing
  def icon(size)
    if !self.icon_file.nil? and !self.icon_file.empty? then
      # show icon
      Package.show_image("/images/apps/"+self.icon_file,size)
    elsif self.is_meta then
      # metapackage without icon, show a metapackage icon
      Package.show_image("/images/apps/Metapackage.png",size)
    elsif self.is_program then
      # program without icon, show a generic icon
      Package.show_image("/images/apps/gnome-other.png",size)
    else  
      # no program, no icon, show nothing
      return ""
    end
  end

  # read in all .desktop files and get locations of icons
  def self.read_icons
    folder = "/usr/share/app-install/desktop"
    # recursively look through all files
    Find.find(folder) do |path|   
       if FileTest.file?(path) then
         local_path = path[folder.length+1, 500]
#         print  "Reading "+local_path+"\n"
         pname = nil
         iname = nil
         popcon = nil
         File.open(path,'r') do |f|
           until f.eof? do
             s = f.gets
             if !(p=find_word("X-AppInstall-Package=",s)).nil? then
               pname = p.chomp # record package name, delete trailing \n
             end
             if !(i=find_word("Icon=",s)).nil? then
               iname = i.chomp # record icon file
             end
             if !(pop=find_word("X-AppInstall-Popcon=",s)).nil? then
               popcon = pop.chomp # record popularity contest
             end             
           end
         end
         if !(pname.nil? || iname.nil?) then
           if iname.index(".").nil? then
             iname+=".png"
           end
           found = true
           path = RAILS_ROOT + "/public/images/apps/"
           if !FileTest.file?(path+iname) then 
             if FileTest.file?(path+iname+".png") then iname +=".png"
             else iname = chop_extension(iname)
               if FileTest.file?(path+iname+".png") then iname +=".png"
               elsif FileTest.file?(path+iname+".gif") then iname +=".gif"
               elsif FileTest.file?(path+iname+".svg") then iname +=".svg"
               else found = false
               end  
             end
           end
           if !found then
             print "#{iname} not found\n"              
           end
#           print "Found package #{pname} with icon #{iname}\n" 
           # add icon file for all packages of this name
           Package.find(:all,:conditions => ["name = ?",pname]).each do |p|
#               print "Added to package #{p.id}\n"
              if found then p.icon_file = iname 
              else 
                p.icon_file = nil                 
                print "#{iname} not found\n" 
              end
              p.is_program = true
              if !popcon.nil? then p.popcon = popcon.to_i end
              p.save
           end
         end
       end
    end    
  end

  def self.chop_extension(fname)
    parts = fname.split(".")
    return parts[0,parts.length-1].join(".")
  end
  
  def self.find_word(w,s)
    if s[0,w.length]==w then
      return s[w.length,s.length-w.length]
    else
      return nil
    end
  end


  def self.adapt_id(id)
    p = Package.find(:first, :conditions => ["id = ?",id])
    if (!p.nil?) && p.distribution_id > 0 then
      return p.repository_id
    else
      return nil
    end
  end
  
  def self.markmc(mc,d)
    dist = Distribution.find(d)
    if !mc.distributions.include?(dist)
          mc.distributions << dist
    end
    der = Derivative.find(1)
    if !mc.derivatives.include?(der)
          mc.derivatives << der
    end      
    der = Derivative.find(2)
    if !mc.derivatives.include?(der)
          mc.derivatives << der
    end   
    
    #adjust package id with new package id stored in repository_id
    pid = adapt_id(mc.base_package_id)
    if (!pid.nil?) then
      mc.base_package_id = pid
      mc.save
    end
  end

  def self.clean_dists
    MetacontentsDistr.find(:all).each do |md|
      if md.metacontent.nil? then
        puts md.id.to_s+" is bad"
      else  
        if md.metacontent.base_package.repository(md.distribution).nil? then
          puts "Removing #{md.metacontent.metapackage.name} / #{md.metacontent.base_package.name} / #{md.distribution.name}"
          md.destroy
        end
      end
    end
  end

  
private
  def self.packages_to_hash url
    if url.nil? then return {:error => I18n.t(:model_package_11)} end
    begin
      file = open(url, 'User-Agent' => 'Ruby-Wget')
    rescue
      return {:error => "Konnte "+url+" nicht lesen"}
    else 
      packages = {}
      reader   = Zlib::GzipReader.new(file)

      while !reader.eof? && line = reader.readline do
        if not line.sub!(/^Package: /, "").nil?
            package = line.chomp
            packages.store package, {}
            readpackage = lambda do |content|
              if !reader.eof? then
                line = reader.readline
                if (not line == "\n")
                    if (line.match(/^ /).nil?)
                        upto_colon = line.match(/^.*: /)
                        option = if upto_colon.nil? then "" 
                                 else upto_colon [0].chop.chop end
                        content = line.gsub(option+": ", "").strip.chomp
                        
                        if is_valid_option? option
                            packages[package].store option, content
                        end
                    else
                        content << (line.chomp)
                    end
                    readpackage.call content
                end
              end  
            end
            readpackage.call ""
        else
           return {:error => I18n.t(:model_package_12,{:file=>url})+":<br><code>"+line+"</code>"}
        end
      end
      return {:packages => packages}
    end
  end
  
  def self.is_valid_option? option
    option == "Version" or option == "Description" or option == "Section" \
     or option == "Depends" or option == "Recommends" \
     or option == "Conflicts" or option == "Suggests" \
     or option == "Installed-Size" or option == "Size" \
     or option == "Filename"
  end
  
end
