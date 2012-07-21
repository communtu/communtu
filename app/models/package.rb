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

# Ubuntu packages, subclass of class base_packages

# database fields: see class BasePackage 

require 'find'

class Package < BasePackage
#  belongs_to :section

  include PackagesHelper
#  belongs_to :distribution
#  belongs_to :repository
  has_many   :comments, :foreign_key => :metapackage_id, :dependent => :destroy
  has_many :metacontents, :foreign_key => :base_package_id
  has_many :metacontents_distrs, :through => :metacontents
  has_many :metacontents_derivatives, :through => :metacontents
  has_many :metapackages, :through => :metacontents
  has_many :package_distrs, :foreign_key => :package_id, :dependent => :destroy
  has_many :package_distrs_architectures, :through => :package_distrs
#  has_many :distributions, :through => :package_distrs
  has_many :repositories, :through => :package_distrs
  has_many :distributions, :through => :package_distrs

  has_many :standard_packages

  has_many :package_tags, :dependent => :destroy
  has_many :tags, :through => :package_tags

  validates_presence_of :name
  validates_uniqueness_of :name

  def repositories_dist(distribution,arch)
    #pds = PackageDistr.find(:all,:conditions=>["package_id = ? and distribution_id = ?",self.id,distribution.id])
    pds = PackageDistr.find(:all,:conditions=>["package_id = ? and distribution_id = ? and package_distrs_architectures.architecture_id = ?",self.id,distribution.id,arch.id],:include => :package_distrs_architectures)
    return pds.map{|pd| pd.repository}
  end

  def is_present(distribution,licence,security,arch)
#    PackageDistr.find(:all,:conditions=>["package_id = ? and distribution_id = ? and repositories.",self.id,distribution.id], :include => :repository)
    !self.repositories_dist(distribution,arch).select{|r| r.security_type<=security && r.license_type<=licence}.empty?
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
  
  def slow_conflicts
    c = Set.[]
    self.package_distrs.each do |pd|
      c.merge(pd.conflicts)
    end
    return c
  end

  #conflicts in a set of pacakges and distributions
  def self.conflicts(package_dists,package_ders)
    all_cons = {}
    Distribution.all.each do |dist|
      Derivative.all.each do |der|
        packages = []
        package_dists.each do |p, dists|
          if dists.map{|d| d.to_i}.include?(dist.id)
            ders = package_ders[p]
            if !ders.nil? and ders.map{|d| d.to_i}.include?(der.id)
              packages << Package.find(p)
            end
          end
        end
        packages.each do |p|
          cons = p.conflicting_packages & packages
          if !cons.empty? then
            if all_cons[p].nil?
              all_cons[p]=cons
            else
              all_cons[p]=(all_cons[p]+cons).uniq
            end
          end
        end
      end
    end
    return all_cons
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
    security_types  = [ I18n.t(:native), I18n.t(:trusted), I18n.t(:third_party) ]
  end

    def self.show_security_type(t)
    if t.nil? then I18n.t(:model_package_2) else security_types[t] end
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
    
  def self.find_packages(search, group, only_programs, exact, page)
    cond_str = "1"
    cond_vals = []
    if not search.nil?
        cond_str += " and name like ?"
          if exact == "1"
            cond_vals << search
          else
            cond_vals << "%" + search + "%"
          end
    end    
    if !(group.nil? or group == "all") 
        cond_str += " and section = ?"
        cond_vals << group
    end
    if only_programs then
        cond_str += " and is_program = ?"
        cond_vals << '1'
    end
    Package.find(:all, #:page => {:size => 10, :current => page}, \
                       :conditions => ([cond_str]+cond_vals), \
                       :order => "popcon desc, name asc")
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
           path = Rails.root.to_s + "/public/images/apps/"
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

  def self.standard_packages(dist,der,arch)
    Package.find(:all,:conditions => ["standard_packages.distribution_id = ? and standard_packages.derivative_id = ? and standard_packages.architecture_id = ?",
                                      dist.id,der.id,arch.id],
                      :include=>:standard_packages)
  end

  # remove all packages that have no repositories
  def self.remove_zombies
    # find all zombies
    # fast query (executed daily)
    zombies = Package.find_by_sql("SELECT base_packages.id \
                    FROM `package_distrs` \
                    RIGHT JOIN base_packages ON base_packages.id=package_id \
                    WHERE base_packages.type=\"Package\" and package_distrs.id IS NULL")
    puts "Removing #{zombies.length} zombie packages"
    # find corresponding metacontents and metapackages
    metas = []
    mcs = []
    # usually, there are no zombies, so we can afford to be slower here...
    zombies.each do |p|
      mcs += Metacontent.find(:all,:conditions=>{:base_package_id=>p.id})
      metas += mcs.map{|mc| mc.metapackage}
    end
    # ... destroy the metacontents
    mcs.compact.uniq.each do |mc|
      mc.destroy
    end
    # .. mark metapackages as modified
    metas.compact.uniq.each do |m|
        m.modified = true
        m.version += ".1"
        m.save
    end
    zombies.each do |p|
      p.destroy
    end
  end
end




