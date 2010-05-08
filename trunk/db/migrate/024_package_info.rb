class PackageInfo < ActiveRecord::Migration
  def self.up
    add_column :base_packages, :filename, :string
    add_column :base_packages, :fullsection, :string
    create_table :dependencies do |t|
      t.integer :base_meta_package_id
      t.integer :base_package_id
      t.integer :dep_type # 0 = depends, 1 = recommends, 2 = conflicts
      t.timestamps
    end

end
    
  def self.down
    remove_column :base_packages, :filename
    remove_column :base_packages, :fullsection
    drop_table :dependencies
  end
end
