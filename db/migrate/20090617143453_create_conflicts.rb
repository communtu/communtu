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
    Conflict.find(:all,:conditions => ["package_id = package2_id"]).each{|c| c.destroy}
    puts "Computing bundle conflicts"
    Metapackage.update_conflicts
  end

  def self.down
    drop_table :conflicts
  end
end
