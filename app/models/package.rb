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

  def repository(distribution)
    pd = PackageDistr.find(:first,:conditions=>["package_id = ? and distribution_id = ?",self.id,distribution.id])
    if pd.nil? then
      return nil
    else
      return pd.repository
    end
  end

  def distributions
    self.package_distrs.map {|pd| Distribution.find(pd.distribution_id)}
  end

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
  
  def meta_intersection(m)
    if repository != m.repository 
      return []
    else 
      self.depends_or_recommends & m.depends_or_recommends
    end
  end
  
  def self.meta_intersections
    metas = Package.find(:all, :conditions => ["section = ?","metapackages"])
    mis = []
    metas.each do |m1|
      metas.each do |m2|
        if m1!=m2 && !m1.is_sub_meta(m2) && !m2.is_sub_meta(m1) && (m1.meta_intersection(m2)).length*10 >= m1.depends_or_recommends.length then mis <<= [m1,m2] end
      end
    end
    return mis
  end

  def stars
    if popcon.nil? then
      nil
    else
      5 * Math.log(popcon>0 ? popcon : 1) / Math.log(Package.maximum(:popcon))
    end
  end

  def self.license_types
    license_types = [ "OpenSource", "Commercial" ]
  end
  
  def self.security_types
    security_types  = [ "Native", "Trusted", "Third-Party" ]
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
        cond_vals << 't'
    end
    Package.find(:all, :page => {:size => 10, :current => page}, \
                       :conditions => ([cond_str]+cond_vals), \
                       :order => "popcon desc, name asc")
  end
  
  def self.get_url_from_source source
    parts = source.split " "
    if parts.length == 4
      # add trailing "/" if necessary
      if parts[1][-1] != 47 then
        parts[1] += "/"
      end
      url = parts[1] + "dists/" + parts[2] + "/" + parts[3] + "/binary-i386/Packages.gz"
      return {:url => url}
    else
      return {:error => source+"<br> hat nicht das richtige Format"}
    end    
  end
  
  def self.import_source repository
    url  = get_url_from_source(repository.url + " " + repository.subtype)
    if !url[:error].nil? then
      return url
    end
    url = url[:url]
    packages = packages_to_hash url 
    distribution_id = repository.distribution_id
    
    if !packages[:error].nil? then
      return packages
    end
    
    info = { "package_count" => packages.size, "update_count" => 0, "new_count" => 0,\
      "failed" => [], "url" => url }

    # enter packages
    packages[:packages].each do |key,package|
 
      if not package["Description"].nil?
        package["Description"] = package["Description"].gsub(/ . /, "<br/>")
      else
        package["Description"] = ""
      end
      
      attributes = { :name => key, :version => package["Version"],\
          :distribution_id => distribution_id, 
          :description => package["Description"],\
          :fullsection => package["Section"],\
          # für :section nur den letzten Teil verwenden
          :section => package["Section"].split("/")[-1],\
          :filename => package["Filename"],\
          :repository_id => repository.id,
          :license_type => repository.license_type}
      
      res = Package.find(:first, :conditions => ["name=? AND version=? AND distribution_id=?",\
        key, package["Version"], distribution_id])
 
      if res.nil?
        
        res= Package.new(attributes)
          
        if res.save
          info["new_count"] = info["new_count"].next 
        else
          info["failed"].push key
        end
        
      else
        if res.update_attributes(attributes)
          info["update_count"] = info["update_count"].next
        else
          info["failed"].push key
        end
      end
    end

    # enter dependency info
    packages[:packages].each do |key,package|
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
      s.split(",").map{|s1| s1.split(" (").first.lstrip}.map{ |name|
        Package.find(:first, :conditions => ["name=? AND distribution_id=?",\
               name, distribution]) }.compact
    end
  end

  
  # display an image in a given size
  def self.show_image(url,size)
      s = size.to_s
      return '<img border="0" height="'+s+'" src="'+url+'"/>'
  end
  
  # display icon for a package, if existing
  def icon(size)
    if !self.icon_file.nil? then
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
  
  # special migration method for a special database containing distributions 1=Gutsy and 2=Hardy
  def migrate
      puts "Package for distribution #{self.distribution_id}"
      p = Package.find(:first, :conditions => ["distribution_id = ? and name = ?",0,self.name])
      if p.nil? then 
        # no new package with same name? then create new package
        # ignore irrelevant and deprecated fields
        p = BasePackage.create(:distribution_id => 0,:repository_id => 0, :name => self.name,
               :section => self.section, :version => nil, :description => self.description, 
               :category_id => self.category_id, :rating => nil, 
               :license_type => self.license_type, :user_id => nil, :published => self.published,
               :created_at => self.created_at, :updated_at => self.updated_at,
               :urls => self.urls, :filename => self.filename, :fullsection => self.fullsection,
               :icon_file => self.icon_file, :is_program => self.is_program, :popcon => self.popcon)
        p.type="Package"
        p.save
        puts("Package "+self.name+" with id "+p.id.to_s+" newly created")
      else #merge package with found package
        puts("Merging packages "+self.id.to_s+" and "+p.id.to_s)
        if self.distribution_id == 2 then
          # hardy packages get priority
          p.description = self.description
          p.category_id = self.category_id
          p.license_type = self.license_type
          if !self.filename.nil? then p.filename = self.filename end
          if !self.fullsection.nil? then p.fullsection = self.fullsection end
          if !self.icon_file.nil? then p.icon_file = self.icon_file end
          if !self.popcon.nil? then p.popcon = self.popcon end
        end
          if p.urls.nil? then p.urls = ""; p.save end
          if !self.urls.nil? && !self.urls=="" then
            p.urls += " "+self.urls
          end  
          p.is_program = p.is_program || self.is_program
          p.save
      end
      PackageDistr.create(:package_id => p.id, :distribution_id => self.distribution_id, :repository_id => self.repository_id, :version => self.version) 
      puts "packagedistr created: pid: #{p.id}, did:#{self.distribution_id}, repid:#{self.repository_id}"
      # store link to new package
      self.repository_id = p.id
      self.save
  end
  
  # migrate from old database structure to new one. Assumes a special database containing distributions 1=Gutsy and 2=Hardy
  def self.migrate_old
    puts "migrate all packages"
    Package.find(:all).each do |p|
      p.migrate
    end
    puts "migrate metapackages"
    Metapackage.find(:all).each do |meta|
      if meta.distribution_id==2 then # keep Hardy bundle
        meta.convert_rating
        meta.metacontents.each do |mc|
          markmc(mc,2)
        end
      else # a Gutsy bundle ... try to find matching Hardy bundle
        meta1 =  Metapackage.find(:first,:conditions => ["distribution_id = ? and name = ?",2,meta.name])
        if meta1.nil? then # no Hardy bundle? then keep Gutsy bundle
          meta.convert_rating
          meta.metacontents.each do |mc|
            markmc(mc,1)
          end
        else # corresponding Hardy bundle found ... 
          meta.metacontents.each do |mc|
            if !mc.base_package.nil? then
              mc1s = meta1.metacontents.select{|mc1| !mc1.base_package.nil? && mc1.base_package.name == mc.base_package.name}
              if mc1s.size==0 then #no package with same name in the bundle, create one
                p = Package.find(:first,:conditions => ["name = ?",mc.base_package.name])
                if !p.nil? then
                  mcnew = Metacontent.create(:metapackage_id => meta1.id, :base_package_id => p.id)
                  markmc(mcnew,1)
                end
              else
                markmc(mc1s[0],1)
              end
            end 
          end  
          meta.destroy
        end
      end
    end

    puts "Adapt all the comments"
    Comment.find(:all).each do |c|
      pid = adapt_id(c.metapackage_id)
      if !pid.nil? then
        c.metapackage_id = pid
        c.save
      end     
    end

    finish_migrate_old
  end
  
  def self.finish_migrate_old
    puts "Adapt all the dependencies"
    last_id = Dependency.find(:last).id
    (0..(last_id/1000)+1).each do |n|
      puts "Adapting the #{n}th thousand"
      Dependency.find(:all,:conditions => ["id >= ? and id < ?",n*1000,(n+1)*1000]).each do |d|
        pid = adapt_id(d.base_meta_package_id)
        if !pid.nil? then
          d.base_meta_package_id = pid
          d.save
        end     
        pid = adapt_id(d.base_package_id)
        if !pid.nil? then
          d.base_package_id = pid
          d.save
      end
    end
  end
  
    puts "Adapt all the videos"
    Video.find(:all).each do |v|
      pid = adapt_id(v.base_package_id)
      if !pid.nil? then
        v.base_package_id = pid
        v.save
      end     
    end

    puts "destroy all old packages"
    Package.find(:all, :conditions => ["distribution_id != ?",0]).each do |p|
        p.destroy
    end

    puts "Migration finished"
  end
  
  def self.clean_dists
    MetacontentsDistr.find(:all).each do |md|
      if md.metacontent.nil? then
        puts md.id.to_s+" is bad"
      else  
        if md.metacontent.base_package.repository(md.distribution).nil? then
          puts "Removing #{md.metacontent.metapackage.name} / #{md.metacontent.base_package.name} / #{md.distribution.name}"
          #md.destroy
        end
      end
    end
  end
private
  def self.packages_to_hash url
    if url.nil? then return {:error => "Konnte keine URL feststellen"} end
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
           return {:error => "Inhalt von "+url+" entspricht nicht Repository-Syntax:<br><code>"+line+"</code>"}
        end
      end
      return {:packages => packages}
    end
  end
  
  def self.is_valid_option? option
    option == "Version" or option == "Description" or option == "Section" \
     or option == "Depends" or option == "Recommends" \
     or option == "Conflicts" or option == "Filename"
  end
  
end
