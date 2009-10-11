namespace :db do
  namespace :repo do
    desc 'Synchronise some repositories, rotate daily within the week.'
    task :sync => :environment do
      Repository.all.each do |r|
        if r.id % 7 == Date.today.cwday-1 then
          puts "Synchronising repository #{r.id}"
          r.import_source
        end
      end
    end
    task :mirrorlist => :environment do
      Repository.write_mirror_list
    end
    task :distributions => :environment do
      Deb.write_conf_distributions
    end
    task :check_debs => :environment do
      cnt = Distribution.count * Derivative.count * Package.license_types.size * Package.security_types.size
      Metapackage.all.each do |m|
        if !m.debianized_version.nil? then
          cmd = "grep \"Package: #{m.debian_name}$\" #{RAILS_ROOT}/public/debs/dists/*/*/binary-i386/Packages |wc -l"
          if (mcnt= IO.popen(cmd).map{|s| s}[0].to_i) != cnt then
            puts "#{m.name} should have #{cnt.to_s} debian packages but has #{mcnt.to_s}"
          end
          if mcnt<cnt then
            puts "Generating the missing debian packages"
            if Deb.find(:first,:conditions => ["metapackage_id = ? and version = ?",m.id,m.version]).nil?
              m.modified = true
              m.save
              m.debianze
            end
            m.fork_generate_debs
          end
        end
      end
    end
  end
end
