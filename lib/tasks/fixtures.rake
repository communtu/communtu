namespace :db do
  namespace :fixtures do
    
    desc 'Create YAML test fixtures from data in an existing database.  
    Defaults to development database.  Set RAILS_ENV to override.'
    task :dump => :environment do
      # shrink database
      puts "Shrinking database, this will take some time"
      m = Metapackage.find_by_name("Textverarbeitung")
      packages = m.all_recursive_packages << m
      ["gdmap", "pdfedit", "Acroread", "Skype", "Virtualbox"].each do |p|
        packages << Package_find_by_name(p)
      end
      BasePackage.all.each do |p|
        if !packages.include?(p) then p.destroy end
      end
      Dependency.find(:all,:conditions=>["package_distr_id is NULL"]).each{|d| d.destroy}
      Dependency.find(:all,:conditions=>["package_distrs.id is NULL"],:include => :package_distr).each{|d| d.destroy}
      User.all.each do |u|
        if u.id > 3 then u.delete end
      end
      sql  = "SELECT * FROM %s"
      skip_tables = ["schema_info","cart_contents", "carts"]
      ActiveRecord::Base.establish_connection(:development)
      (ActiveRecord::Base.connection.tables - skip_tables).each do |table_name|
        puts "generating fixture for #{table_name}"
        i = "000"
        File.open("#{RAILS_ROOT}/test/fixtures/#{table_name}.yml", 'w') do |file|
          data = ActiveRecord::Base.connection.select_all(sql % table_name)
          file.write data.inject({}) { |hash, record|
            hash["#{table_name}_#{i.succ!}"] = record
            hash
          }.to_yaml
        end
      end
    end
  end
end
