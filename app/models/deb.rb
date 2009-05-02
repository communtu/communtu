class Deb < ActiveRecord::Base
  belongs_to :metapackage
  belongs_to :distribution
  belongs_to :derivative

  require 'utils'

  # generate debian package
  def generate
    # create a lock in order to avoid concurrent debianizations
    safe_system "dotlockfile #{RAILS_ROOT}/debs/lock"
    begin
      meta = self.metapackage
      dist = self.distribution
      der = self.derivative
      lic = self.license_type
      sec = self.security_type
      name = meta.debian_name
      mlic = meta.compute_license_type
      msec = meta.compute_security_type
      codename = Metapackage.codename(dist,der,lic,sec)
      version = "#{meta.version}-#{codename}1"
      f=File.open("#{RAILS_ROOT}/log/debianize.log","a")
      f.puts
      f.puts
      f.puts "++++++++++++++++++++++ Processing version #{name}-#{version}"
      f.puts
      f.close
      # compute list of packages contained in metapackage (todo: delegate this to an own method, preferably using more :includes)
      mcs = Metacontent.find(:all,:conditions => 
             ["metapackage_id = ? and metacontents_distrs.distribution_id = ? and metacontents_derivatives.derivative_id = ?",
              meta.id,dist.id,der.id],:include => [:metacontents_distrs, :metacontents_derivatives])
      packages = mcs.map{|mc| mc.base_package}.select{|p| p.is_present(dist,lic,sec)}.map{|p| p.debian_name}
      
      begin
        # build metapackage
        debfile = Metapackage.makedeb(name,version,packages,meta.description,codename,Derivative.find(:first),[])
  
        # make name of .deb unique by adding the codename
        # newfile = debfile.gsub("_all.deb","~"+codename+"_all.deb")
        # safe_system "mv #{debfile} #{newfile}"
        newfile = debfile

        # what license types and security types are actually used in the bundle?
        # use this info to determine the component
        component = Metapackage.components[[lic,mlic].min][[sec,msec].min]
        # upload metapackage
        # todo: make name of .deb unique
        puts "Uploading #{newfile}"
        safe_system "reprepro -v -b #{RAILS_ROOT} --outdir public/debs --confdir debs --logdir log --dbdir debs/db --listdir debs/list -C #{component} includedeb #{codename} #{newfile} >> #{RAILS_ROOT}/log/debianize.log 2>&1"
        # remove package files, but not folder
        safe_system "rm #{RAILS_ROOT}/debs/#{name}/#{name}* >/dev/null 2>&1 || true"
        self.generated = true
        self.errmsg = nil
        self.log = IO.popen("tail -n80 #{RAILS_ROOT}/log/debianize.log").read
        self.save
      rescue StandardError => err
        self.generated = false
        self.errmsg = err
        self.log = IO.popen("tail -n80 #{RAILS_ROOT}/log/debianize.log").read
        self.save
      end
    rescue 
        self.generated = false
        self.errmsg = "unknown"
        self.log = IO.popen("tail -n80 #{RAILS_ROOT}/log/debianize.log").read
        self.save
      f=File.open("#{RAILS_ROOT}/log/debianize.log","a")
      f.puts
      f.puts "Debianizing #{name} failed! (id = #{id})"
      f.puts
      f.close
    end  
    # cleanup
    system "rm -r #{RAILS_ROOT}/debs/#{meta.debian_name}*"
    # release lock
    safe_system "dotlockfile -u #{RAILS_ROOT}/debs/lock"
  end
end
