class AddIndexToPackages < ActiveRecord::Migration
  def self.up
    add_index :base_packages, :name
  end

  def self.down
    remove_index :base_packages, :name
  end
end
