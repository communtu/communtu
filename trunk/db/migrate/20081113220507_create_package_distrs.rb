class CreatePackageDistrs < ActiveRecord::Migration
  def self.up
    create_table :package_distrs do |t|
      t.integer :package_id
      t.integer :distribution_id
      t.integer :repository_id
      t.integer :size
      t.timestamps
    end
    
    add_column :dependencies, :package_distr_id, :integer
  end

  def self.down
    drop_table :package_distrs
    remove_column :dependencies, :package_distr_id
  end
end
