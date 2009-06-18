class CreateConflicts < ActiveRecord::Migration
  def self.up
    create_table :conflicts do |t|
      t.integer :package_id
      t.integer :package2_id

      t.timestamps
    end
    #YAML::load_file("db/migrate/conflicts.yml").each do |p,conflicts|
    puts "Computing package conflicts"
    Package.all.each do |p|
      puts p.id
      p.slow_conflicts.each do |c|
        Conflict.create(:package_id => p.id, :package2_id => c.id)
      end
    end
    puts "Computing bundle conflicts"
    begin
      modified = false
      puts "New iteration"
      Metapackage.all.each do |m|
        puts m.id
        m.base_packages.each do |p|
          p.conflicting_packages.each do |cp|
            if Conflict.find(:first,:conditions => {:package_id => p.id, :package2_id => cp.id}).nil?
              modified = true
              Conflict.create(:package_id => p.id, :package2_id => cp.id)
            end
          end
        end
      end
    end while modified
  end

  def self.down
    drop_table :conflicts
  end
end
