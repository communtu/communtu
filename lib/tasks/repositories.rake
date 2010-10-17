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
      # cleanup database
      MetacontentsDistr.cleanup
      MetacontentsDerivative.cleanup
      Package.remove_zombies
      Metapackage.remove_dangling_packages
      # handle old cds that are still "generating"
      Livecd.find_all_by_generating(true).select{|cd| Time.now-cd.updated_at > 10000}.each do |cd|
        cd.generating=false
        cd.failed=true
        cd.log="Error: timeout, process did not terminate"
        cd.save
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
      cnt = Distribution.find_all_by_invisible(false).count * Derivative.count * Package.license_types.size * Package.security_types.size
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
    end  
    task :generate_debs => :environment do
      limit = 500
      debs = Deb.find(:all,:conditions=>{:generated=>:false},:limit=>limit)
      cnt = debs.size
      if cnt>0 then
        start_date = IO.popen("date").read.chomp
        system "echo 'starting at #{start_date}' >> log/generate_debs.log"
        s = if cnt==limit then "first "+limit.to_s else cnt.to_s end
        puts "  ... generating the #{s} missing debian packages"
        debs.each do |d|
           system "echo 'started at #{start_date}, #{cnt} left' >> log/generate_debs.log"
           system 'echo "Deb.find('+d.id.to_s+').generate" | script/console production'
           cnt -= 1
        end
      end
      return true
    end
    task :verify_debs => :environment do
      Deb.all.each do |d|
        system 'echo "Deb.find('+d.id.to_s+').verify" | script/console production'
      end
    end
  end
end
namespace :livecd do
  desc 'Daemon for creating LiveCDs'
  task :daemon => :environment do
    ports = SETTINGS['kvm_ports']
    admin_ports = [ports.pop,ports.pop]
    loop do
      Livecd.remaster_next(ports,admin_ports)
      sleep 10
    end
  end
end