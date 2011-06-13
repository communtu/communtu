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
      # concurrent instance already running? then exit
      if IO.popen("ps -aef |grep generate_debs | grep rake | grep -v grep",&:read).split("\n").size<=1 then
        limit = 100
        debs = Deb.find(:all,:conditions=>{:generated=>:false},:limit=>limit)
        cnt = debs.size
        if cnt>0 then
          start_date = IO.popen("date",&:read).chomp
          system "echo 'starting at #{start_date}' >> log/generate_debs.log"
          s = if cnt==limit then "first "+limit.to_s else cnt.to_s end
          puts "  ... generating the #{s} missing debian packages"
          debs.each do |d|
             system "date >> log/generate_debs.log"
             system "echo 'started at #{start_date}, #{cnt} left' >> log/generate_debs.log"
             d.generate #system 'echo "Deb.find('+d.id.to_s+').generate" | script/console production'
             cnt -= 1
          end
        end
      end
    end
    desc 'Verify some repositories, rotate daily within the month.'
    task :verify_debs => :environment do
      interval = 100 # number of debs to generate by one ruby process (small=takes long, large=consumes memory)
      debs = Deb.all.select do |d|
        d.id % 30 == (Date.today-Date.today.beginning_of_year).to_i % 30
      end
      (0..debs.length / interval).each do |i|
        debstring = debs[i*interval..(i+1)*interval-1].map{|d| d.id.to_s}.join(",")
        system "echo \"[#{debstring}].each{|i| Deb.find(i).verify}\" | script/console production"
      end
    end
  end
end

namespace :bundle do
  desc 'Check all bundles for conflicts'
  task :conflicts => :environment do
    Metapackage.all.each do |b|
      b.edos_conflicts
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

  desc 'Compute new database columns for old LiveCDs'
  task :adjust_db => :environment do
    Livecd.all.each do |cd|
      cd.published = cd.bundles_published?
      cd.save
    end  
    Dir.glob("/var/log/apache2/*-communtu.log*gz").each do |file|
      IO.popen("gunzip -c #{file}").each do |line|
        cdname = line.scan(/.*\/isos\/(.*).iso.*/).flatten[0]
        if !cdname.nil?
          puts cdname
          Livecd.all.select{|cd| cd.fullname == cdname}.each do |cd|
            cd.downloaded += 1
            cd.save
            puts cd.name
          end
        end
      end
    end
  end

  desc 'Count new livecd-downloads from yesterday'
  task :counter => :environment do
    Livecd.all.each do |cd|
      cd.published = cd.bundles_published?
      cd.save
    end
    date = Date.yesterday.strftime("%d/%b/%Y")
    puts date
    Dir.glob("/var/log/apache2/*-communtu.log").each do |file|
      IO.popen("grep #{date} #{file}").each do |line|
         scan_cds(line)
      end
    end
    Dir.glob("/var/log/apache2/*-communtu.log.1").each do |file|
      IO.popen("grep #{date} #{file}").each do |line|
         scan_cds(line)
      end
    end
    Dir.glob("/var/log/apache2/*-communtu.log*gz").each do |file|
      IO.popen("gunzip -c #{file} | grep #{date}").each do |line|
        scan_cds(line)
      end
    end
  end

end

def scan_cds(line)
   cdname = line.scan(/.*\/isos\/(.*).iso.*/).flatten[0]
   if !cdname.nil?
     puts cdname
     Livecd.all.select{|cd| cd.fullname == cdname}.each do |cd|
       cd.downloaded += 1
       cd.save
       puts cd.name
     end
   end
end