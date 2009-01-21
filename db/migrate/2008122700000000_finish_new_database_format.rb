class FinishNewDatabaseFormat < ActiveRecord::Migration
  def self.up
#  remove_column :base_packages, :distribution_id
#  remove_column :base_packages, :repository_id
#  remove_column :base_packages, :version
#  remove_column :base_packages, :rating
##  add_column :base_packages, :security_type, :integer
#  remove_column :base_packages, :filename
#  add_column :package_distrs, :filename, :string
#  add_column :package_distrs, :size, :integer # in bytes
#  add_column :package_distrs, :installedsize, :integer # in bytes
  drop_table :dependencies
  create_table :dependencies do |t|
      t.integer :package_distr_id
      t.integer :base_package_id
      t.integer :dep_type # 0 = depends, 1 = recommends, 2 = conflicts
      t.timestamps
  end
end
    
  def self.down
  end
end
