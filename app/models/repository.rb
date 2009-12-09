require 'open-uri'
require 'zlib'
require 'lib/utils'

class Repository < ActiveRecord::Base
  belongs_to :distribution
  has_many :package_distrs, :dependent => :destroy
  has_many :packages, :through => :package_distrs
  validates_presence_of :license_type, :url, :distribution_id
  
  def name
    self.url+" "+self.subtype
  end

  # folder for storing package info
  def dir_name
    distribution.dir_name
  end

  # file for storing package info
  def file_name arch
    self.dir_name + "/" + self.id.to_s + "_" + arch.name
  end
  
  # migrate a repository to a different distribution
  def migrate(dist)
    newurl = url.gsub(self.distribution.short_name.downcase, \
                      dist.short_name.downcase)
    Repository.create({:distribution_id => dist.id,
                       :security_type => security_type,
                       :license_type => license_type,
                       :type => type,
                       :url => newurl,
                       :subtype => subtype,
                       :gpgkey => gpgkey})
  end

  # write repository list for usage with apt-mirror
  def self.write_mirror_list
    f = File.open("mirror.list","w")
    f.puts "set nthreads     20"
    f.puts "set _tilde 0"
    Repository.all.each do |r|
      ["i386","amd64"].each do |arch|
        plain_url = r.url.gsub(/deb /,"")
        f.puts "deb-#{arch} #{plain_url} #{r.subtype}"
      end
    end
    f.puts "clean http://archive.ubuntu.com/ubuntu"
    f.close
  end

  def self.get_url_from_source source, arch
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
        url = parts[1] + "dists/" + parts[2] + "/" + parts[3] + "/binary-#{arch.name}/Packages.gz"
      end
      return {:url => url}
    else
      return {:error => source+I18n.t(:model_package_6)}
    end
  end

  # test whether a source is present
  def test_source 
    arch = Architecture.find(:first)
    url  = Repository.get_url_from_source(self.name,arch)[:url]
    if url.nil? then return {:error => I18n.t(:model_package_7,{:repo=> self.url + " " + self.subtype})} end
    begin
      file = open(url, 'User-Agent' => 'Ruby-Wget')
    rescue
      return {:error => url}
    else
      return {}
    end
  end


  # import repository info from the url
  def import_source
    # need lock in order to ensur that only we mark things as outdated
    safe_system "dotlockfile -r 1000 #{RAILS_ROOT}/repo_lock"
    infos = {}
    first_run = true
    Architecture.all.each do |arch|
      infos[arch] = import_source_arch arch, first_run
      if !infos[arch]["package_count"].nil? then
        first_run = false
      end
    end
    # remove orphans
    PackageDistrsArchitecture.destroy_all(:outdated => true)
    PackageDistr.destroy_all(:outdated => true)
    safe_system "dotlockfile -u #{RAILS_ROOT}/repo_lock"
    return infos
  end

  protected
  # these methods should not be called from outside, since they depend on proper preparation

  # import repository for on architecture
  def import_source_arch arch, first_run

    distribution_id = self.distribution_id

    # get URL for repository
    url  = Repository.get_url_from_source(self.name,arch)

    # repository not found? then return
    if !url[:error].nil? then
      return url
    end
    url = url[:url]

    # read in all packages from repository
    tmp_name = (IO.popen "mktemp").read.chomp
    packages = self.packages_to_hash url, arch, tmp_name
    # errors while reading or still up-to-date? then return
    if !packages[:error].nil? or !packages[:notice].nil? then
      return packages
    end

    if first_run
      # mark all PackageDistrs for this repository as outdated
      PackageDistr.find(:all,:conditions => ["repository_id = ?",self.id]).each do |pd|
        pd.outdated = true
        pd.save
      end
    end
    
    # mark all PackageDistrsArchitectures for this repository and architecture as outdated
    PackageDistrsArchitecture.find(:all,:conditions => ["package_distrs.repository_id = ? and architecture_id = ?",self.id,arch.id],:include=>:package_distr).each do |pda|
      pda.outdated = true
      pda.save
    end
    
    info = { "package_count" => packages[:packages].size, "update_count" => 0, "new_count" => 0,\
      "failed" => [], "url" => url }

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
          # use last part for :section
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
            :repository_id => self.id,
            :size => package["Size"],
            :installedsize => package["Installed-Size"]}

      # compute license type by minimum with existing one
      if p.license_type.nil? then
        p.license_type = self.license_type
      else
        p.license_type = min(self.license_type,p.license_type)
      end

      # compute security type by minimum with existing one
      if p.security_type.nil? then
        p.security_type = self.security_type
      else
        p.security_type = min(self.security_type,p.security_type)
      end

      # update package_distr
      pd = PackageDistr.find(:first, :conditions =>
             ["package_id = ? and repository_id = ?",p.id,self.id])
      if pd.nil?
        # no package_distr? create a new one
          pd = PackageDistr.new(attributes_package_distr)
          if !pd.save then
            info["failed"].push(name + " " + self.url)
          end
      else
        # package exists, then update attributes
          if !pd.update_attributes(attributes_package_distr) then
            info["failed"].push(name + " " + self.url)
          end
      end
      if !pd.nil? then
          # enter architecture
          if  (pda=PackageDistrsArchitecture.find(:first,:conditions => ["package_distr_id = ? and architecture_id = ?",pd.id,arch.id])).nil? then
              PackageDistrsArchitecture.create(:package_distr_id => pd.id, :architecture_id => arch.id,:outdated => false)
          else
            pda.outdated = false
            pda.save
          end
          pd.outdated = false
          pd.save
      end
    end # packages[:packages].each
    # enter dependency info - this must happen *after* creation of the packages!
    # do this only for the first architecture (usually i386)
    # we generally only have a rough approximation of the dependencies
    if arch.id==1 then
      packages[:packages].each do |name,package|
        p = Package.find(:first, :conditions => ["name=?",name])
        if not p.nil?
          pd = PackageDistr.find(:first, :conditions =>
             ["package_id = ? and repository_id = ?",p.id,self.id])
          if not pd.nil?
            pd.dependencies.delete_all
            pd.assign_depends(Repository.parse_dependencies(package["Depends"]))
            pd.assign_recommends(Repository.parse_dependencies(package["Recommends"]))
            pd.assign_suggests(Repository.parse_dependencies(package["Suggests"]))
            pd.assign_conflicts(Repository.parse_unversioned_dependencies(package["Conflicts"]))
          else raise I18n.t(:model_package_9,{:repo_name => self.name, :package_name => p.name})
          end
        else raise I18n.t(:model_package_10,{:repo_name => self.name, :package_name => name})
        end
      end
    end
    # store new package list
    system "mkdir -p #{self.dir_name}"
    system "mv #{tmp_name} #{self.file_name arch}"
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

  # parse Packages file at url for arch, save it in tmp_name and return infos about contained packages
  def packages_to_hash url, arch, tmp_name
    if url.nil? then return {:error => I18n.t(:model_package_11)} end
    begin
      file = open(url, 'User-Agent' => 'Ruby-Wget')
    rescue
      return {:error => I18n.t(:model_package_could_not_read,:url => url)}
    else
      # check whether repository contents has changed
      tmp_file = File.open(tmp_name+".gz","w")
      tmp_file.write file.read
      tmp_file.close
      system "gunzip -f #{tmp_name}.gz"
      # contents unchanged? then we are done
      if system "diff #{tmp_name} #{self.file_name arch}" then
        return {:notice => I18n.t(:model_package_need_not_update,:url => url)}
      end
      file.seek(0,IO::SEEK_SET)
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

                        if Repository.is_valid_option? option
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
           return {:error => I18n.t(:model_package_12,{:file=>url})+":<br /><code>"+line+"</code>"}
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
