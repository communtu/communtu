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

# Communtu bundles; subclass of base_packages
# should be renamed to class Bundle in the future

# database fields: see class BasePackage 

class Metapackage < BasePackage

  require 'set.rb'
  require 'utils'
  require "lib/utils.rb"
    
  has_many   :metacontents, :dependent => :destroy
  has_many   :base_packages, :through => :metacontents
  has_many   :debs # destroy via callback
#  has_many   :packages, :through => :metacontents, :source => :base_package, :foreign_key => :base_package_id 
  belongs_to :category
  belongs_to :user
  has_many :livecds, :dependent => :destroy
  
  acts_as_rateable
  
  validates_presence_of :license_type, :user, :category # , :version, :description
  
  def name
    trans = translation(self.name_tid)
    if trans == "unknown"
    trans = "Neues Bündel"
    end
    return trans
  end

  def name_english
    trans = Translation.find(:first, :conditions => {:translatable_id => self.name_tid, :language_code => "en"})
    if trans != nil
     return trans.contents
    else
     return ""
    end
  end

  def description_english
    trans = Translation.find(:first, :conditions => {:translatable_id => self.description_tid, :language_code => "en"})
    if trans != nil
      return trans.contents
    else
      return ""              
    end
  end

  def description
    trans = translation(self.description_tid)
    if trans == "unknown"
    trans = ""
    end
    return trans
  end
 
  def cant_be_debianized
    self.name_english == "" or self.name_english == nil or self.description_english == "" or self.description_english == nil
  end

  def owned_by? user
    (user_id == user.id)
  end
  
  def is_published?
    return self.published==1 
  end

  # contained packages (without bundles)
  def packages
    base_packages.select{|p| p.class == Package}
  end

  # contained bundles
  def children
    base_packages.select{|p| p.class == Metapackage}
  end

  # descendants
  def descendants
    children.map do |c|
      c.children << c
    end.flatten
  end
  
  # metapackages using this one
  def metapackages
    Metapackage.find(:all,:conditions => ["metacontents.base_package_id = ?",self.id], :include => :metacontents)
  end

  def metacontents_for(package)
    Metacontent.find(:first,:conditions => ["metapackage_id = ? and base_package_id = ?",self.id,package.id])
  end

  # list of packages used for generation of debian metapackage
  def package_names_for_deb(dist,der,lic,sec,arch)
      ps = Package.find_by_sql("SELECT DISTINCT base_packages.id, base_packages.name \
               FROM `base_packages`  \
               INNER JOIN metacontents ON (base_packages.id = metacontents.base_package_id) \
               INNER JOIN package_distrs ON (package_distrs.package_id=base_packages.id) \
               INNER JOIN package_distrs_architectures ON (package_distrs_architectures.package_distr_id=package_distrs.id) \
               INNER JOIN metacontents_distrs ON (metacontents.id = metacontents_distrs.metacontent_id)  \
               INNER JOIN metacontents_derivatives ON (metacontents.id = metacontents_derivatives.metacontent_id)  \
               INNER JOIN repositories ON (package_distrs.repository_id=repositories.id) \
               WHERE metacontents.metapackage_id = #{self.id} \
                     AND package_distrs_architectures.architecture_id = #{arch.id} \
                     AND package_distrs.distribution_id = #{dist.id} \
                     AND metacontents_distrs.distribution_id = #{dist.id} \
                     AND metacontents_derivatives.derivative_id = #{der.id} \
                     AND repositories.security_type <= #{sec} \
                     AND repositories.license_type <= #{lic}")
      ms = Metapackage.find_by_sql("SELECT DISTINCT base_packages.id, base_packages.name, base_packages.published, base_packages.name_tid \
               FROM `base_packages`  \
                   INNER JOIN metacontents ON (base_packages.id = metacontents.base_package_id) \
               WHERE metacontents.metapackage_id = #{self.id}
                     AND base_packages.type = \"Metapackage\"")
      return (ps+ms).map{|p| p.debian_name}
  end

  # close a list of bundles under dependencies
  def self.close_deps(bundles)
    bundles.each do |b|
      b.base_packages.each do |b1|
        if b1.class == Metapackage and !bundles.include?(b1)
          bundles << b1
        end
      end
    end
  end

  #conflicts within the bundle
  def internal_conflicts
    packages = self.base_packages
    all_cons = {}
    packages.each do |p|
      cons = p.conflicting_packages & packages
      if !cons.empty? then
        mcp = metacontents_for(p)
        newcons = cons.clone
        cons.each do |c|
          mcc = metacontents_for(c)
          if (mcp.distributions & mcc.distributions).empty? or (mcp.derivatives & mcc.derivatives).empty?
            newcons.delete(c)
          end
        end
        if !newcons.empty? then
          all_cons[p]=newcons
        end
      end
    end
    return all_cons
  end

  def self.update_conflicts
    begin
      puts "New iteration"
      modified = false
      Metapackage.all.each do |m|
        m.base_packages.each do |p|
          p.conflicting_packages.each do |cp|
            if Conflict.find(:first,:conditions => {:package_id => m.id, :package2_id => cp.id}).nil?
              modified = true
              Conflict.create(:package_id => m.id, :package2_id => cp.id)
            end
          end
        end
      end
    end while modified
  end

  # use edos_checkdeb for detection of conflicts
  # all=true: also find conflicts in all bundles that are introduced by modifying the present one (see #542)
  # before using this, #1212 should be fixed first, such that we can use the "current version" (and not the "debianized version") 
  def edos_conflicts(all=false)
    name = self.debian_name
    bundle_names = if all then
      Metapackage.all.map(&:debian_name).join(",")
    else
      name
    end  
    description = "test"
    errs = []
    # use largest license and security type, this should reveal all conflicts  
    license, security = 1, 2
    Distribution.all.each do |dist|
      Architecture.all.each do |arch|
        # get all package lists, and decorate them with the derivatives that led to them 
        package_lists = {}
        Derivative.all.each do |der|
          list = package_names_for_deb(dist,der,license,security,arch)
          if package_lists[list].nil? then
            package_lists[list] = [der]
          else
            package_lists[list] << der
          end
        end
        # for each package list, compute the errors
        errs += package_lists.map do |package_names,ders|
          # get repositories needed for bundle
          package_names = []
          repos = Set.[]
          self.recursive_packages package_names, repos, dist, arch, license, security
#          repos = dist.repositories
          puts repos.map(&:name)
          repo_files = repos.map{|r| r.file_name(arch)}.join(" ")  
#          repo_files = dist.dir_name + "/[0-9]*#{arch.name}"
          # generate control file for bundle
          tmpdir = IO.popen("mktemp -d",&:read).chomp
          res = ""
          Dir.chdir tmpdir do
            # get all Communtu Package files, remove current bundle
            File.open("Packages","w") do |f|
              skip=false
              IO.popen("cat #{dist.package_files(arch)}").each do |line|
                if skip then
                  skip = /^Package:/.match(line).nil?
                end  
                if !/^Package: #{name}/.match(line).nil? then
                  skip = true
                end
                if !skip then
                  f.puts line
                end
              end
            end
            Deb.write_control(name,package_names,description,1)
            call = "cat Packages #{repo_files} control | edos-debcheck -quiet -explain -checkonly #{bundle_names} |grep -v ^Depends"
            puts tmpdir, call
            res = IO.popen(call,&:read)
          end
          # system "rm -r #{tmpdir}"
          if res.include?("FAILED") then
            "*** error for #{name} #{dist.name} #{arch.name} #{ders.map(&:name).join(",")}:\n #{res}\n"           
          else
            nil
          end
        end
      end
    end
    self.conflict_msg = errs.select{|e| not e.nil?}.join("\n")
    self.save
    return self.conflict_msg
  end

  # this function is needed to complement is_present for class Package
  def is_present(distribution,licence,security,arch)
    true
  end

  def compute_license_type
    (self.base_packages.map{|p| p.compute_license_type} <<0).max
  end
  
  def compute_security_type
    (self.base_packages.map{|p| p.compute_security_type} <<0).max
  end
  
   def installedsize(dist)
     self.base_packages.map{|p| p.installedsize(dist)}.compact.sum
  end
  
  # copy the metapackage contents from from_dist to to_dist
  def migrate(from_dist, to_dist)
    not_found = []
    self.metacontents.each do |mc|
      # look for the mcs belonging to from_dist
      # *and* having packages available for to_dist
      if mc.distributions.include?(from_dist)
        if mc.base_package.class != Package 
          # bundle, always append it
          append = true
        else
          # package, only append it if present in the distribution
          if mc.base_package.distributions.include?(to_dist)
            append = true
          else
            not_found << mc.base_package
            append = false
          end
        end
        if append && !mc.distributions.include?(to_dist)
          MetacontentsDistr.create({:metacontent_id => mc.id, :distribution_id => to_dist.id})
          self.modified = true
          self.save
        end
      end
    end
    if self.modified then
      self.version += ".1"
      self.save
      self.debianize
    end
    return not_found    
  end
  
  # icon for bundles
  def self.icon(size)
    s = size.to_s
    return '<img border="0" height="'+s+'" width="'+s+'" src="/images/apps/Metapackage.png"/>'
  end
  def icon(s)
    Metapackage.icon(s)
  end

## installation and creating debian metapackages

  # get all package names and all repositories that a bundle depends on
  def recursive_packages package_names, package_sources, dist, arch, license, security
    self.base_packages.each do |p|
        if p.class == Package
            reps = p.repositories_dist(dist,arch).select{|r| r.security_type<=security && r.license_type<=license}
            if !reps.empty? then
              package_names.push(p.name)
              reps.each do |rep|
                package_sources.add(rep)
              end
            end
        else
            p.recursive_packages package_names, package_sources, dist, arch, license, security
        end
    end
  end

  # get all repositories that a bundle needs, each with the list of packages that lead to the need for that repository 
  def recursive_packages_sources package_sources, dist, arch, license, security
    self.base_packages.each do |p|
        if p.class == Package
            reps = p.repositories_dist(dist,arch).select{|r| r.security_type<=security && r.license_type<=license}
            if !reps.empty? then
              reps.each do |rep|
                if package_sources[rep].nil? then
                  package_sources[rep] = [p]
                else  
                  package_sources[rep] << p
                end
              end
            end
        else
            p.recursive_packages_sources package_sources, dist, arch, license, security
        end
    end
  end

  def debianize(ders=nil)
    # start with version 0.1 if there is none
    if self.version.nil? or self.version.empty? then
      self.version = "0.1"
      self.debianized_version = "0.1"
      self.save
    end
    # abort if it does not make sense to debianize
    if self.debianizing
      return false
    end
    self.debianized_version = self.version
    self.debianizing = true
    self.save
    # generate debs
    if ders.nil? then
      ders = Derivative.all
    end
    ders.each do |der|
      der.distributions.each do |dist|
        (0..1).each do |lic|
          (0..2).each do |sec|
            codename = Deb.compute_codename(dist,der,lic,sec)
            version = "#{self.version}-#{codename}"
            params = {:metapackage_id => self.id, :distribution_id => dist.id, :derivative_id => der.id,
                      :license_type => lic, :security_type => sec, :version => self.version}
            if Deb.find(:first,:conditions=>params).nil? then
               Deb.create(params.merge({:url => version, :generated => false}))
            end
          end
        end
      end
    end
    return true
  end
  
  def generate_debs
    # generate debian packages from debs
    Deb.find(:all,:conditions => ["metapackage_id = ? and version = ? and generated = ?",self.id,self.version,false]).each do |deb|
      deb.generate
    end
    return true
  end

  def generate_debs_then_unlock
    generate_debs
    safe_system "dotlockfile -u #{RAILS_ROOT}/forklock"
  end

  def fork_generate_debs
    # only allow one fork at a time, in order to prevent memory leaks
    safe_system "dotlockfile -r 1000 #{RAILS_ROOT}/forklock"
    fork do
      ActiveRecord::Base.connection.reconnect!
      system 'echo "Metapackage.find('+self.id.to_s+').generate_debs_then_unlock" | nohup script/console production'
    end
    ActiveRecord::Base.connection.reconnect!
  end
  
  def self.debianize_all
    Metapackage.all.each do |m|
      puts
      puts
      puts "++++++++++++++++++++++ Processing package #{m.name}"
      puts
      m.debianize
    end
  end 

  # adpat list of metacontents (for bundle editing)
  def adapt_mcs(packages)
    if packages.nil? then
      mcs = self.metacontents
    else
      mcs = []
      # remove the deselected packages
      self.metacontents.each do |mc|
        if packages.include?(mc.package) then
          mcs << mc
          packages.delete(mc.package)
        end
      end
      # create preliminary mcs for the new packages
      packages.each do |p|
        mcs << Metacontent.new({:metapackage_id => self.id, :base_package_id => p.id})
      end
    end
    return mcs.sort_by {|mc| [mc.package.section, mc.package.ptype, mc.package.name]}
  end

  def self.remove_dangling_packages
      metas = []
      mcds = MetacontentsDistr.find_by_sql("SELECT metacontents_distrs.id \
               FROM `metacontents_distrs`  \
               INNER JOIN metacontents ON (metacontents.id = metacontents_distrs.metacontent_id)  \
               INNER JOIN base_packages ON (base_packages.id = metacontents.base_package_id) \
               WHERE (base_packages.id, metacontents_distrs.distribution_id) NOT IN (SELECT package_id, distribution_id FROM package_distrs)")
      puts "Removing #{mcds.length} dangling packages from bundles"
      mcds.each do |mcd|
        if !mcd.metacontent.nil?
          metas << mcd.metacontent.metapackage
        end
        mcd.destroy
      end
      metas.compact.uniq.each do |m|
        m.modified = true
        m.version += ".1"
        m.save
      end
  end

  protected
  
  # :dependent => :destroy will not work since the metapackage is needed for destroying the debs
  def before_destroy
    Deb.destroy(self.debs.map{|d| d.id})
  end
  
end
