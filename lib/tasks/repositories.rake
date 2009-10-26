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
    desc 'Synchronise all repositories.'
    task :sync_all => :environment do
      Repository.all.each do |r|
          puts "Synchronising repository #{r.id}"
          r.import_source
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
        puts m.name
        if !m.debianized_version.nil? then
          cmd = "grep \"Package: #{m.debian_name}$\" #{RAILS_ROOT}/public/debs/dists/*/*/binary-i386/Packages |wc -l"
          if (mcnt= IO.popen(cmd).map{|s| s}[0].to_i) != cnt then
            puts "  ... should have #{cnt.to_s} debian packages but has #{mcnt.to_s}"
          end
          if mcnt<cnt then
            if Deb.find(:first,:conditions => ["metapackage_id = ? and version = ? and generated = ?",m.id,m.version,false]).nil?
              puts "  ... generating new debs"
              m.modified = true
              m.save
              m.debianize
            end
          end
        end
      end
      puts "  ... generating the first 1000 missing debian packages"
      Deb.find(:all,:conditions=>{:generated=>:false},:limit=>1000).each do |d|
         system 'echo "Deb.find('+d.id.to_s+').generate" | script/console production'
      end
      return true
    end
  end
end
