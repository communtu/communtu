class CreatePackageDistrs < ActiveRecord::Migration
  def self.up
    create_table :package_distrs do |t|
      t.integer :package_id
      t.integer :distribution_id
      t.integer :repository_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table :package_distrs
  end
end
