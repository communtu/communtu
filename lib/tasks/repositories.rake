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
  end
end
