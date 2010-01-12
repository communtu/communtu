class CreateStandardPackages < ActiveRecord::Migration
  def self.up
    create_table :standard_packages do |t|
      t.integer :package_id
      t.integer :distribution_id
      t.integer :derivative_id
      t.integer :architecture_id

      t.timestamps
    end
  end

  def self.down
    drop_table :standard_packages
  end
end
