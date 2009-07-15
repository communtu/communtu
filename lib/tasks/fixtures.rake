namespace :db do
  namespace :fixtures do
    
    desc 'Create YAML test fixtures from data in an existing database.  
    Defaults to development database.  Set RAILS_ENV to override.'
    task :dump => :environment do
      # shrink database
      puts "Shrinking database, this will take some time"
      m = Metapackage.find_by_name("Textverarbeitung")
      packages = m.all_recursive_packages << m
      BasePackage.all.each do |p|
        if !packages.include?(p) then p.destroy end
      end
      User.all.each do |u|
        if u.id > 5 then u.destroy end
      end
      sql  = "SELECT * FROM %s"
      skip_tables = ["schema_info","cart_contents", "carts"]
      ActiveRecord::Base.establish_connection(:development)
      (ActiveRecord::Base.connection.tables - skip_tables).each do |table_name|
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
