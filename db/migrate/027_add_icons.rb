class AddIcons < ActiveRecord::Migration
  def self.up
    add_column :base_packages, :icon_file, :string
end
    
  def self.down
    remove_column :base_packages, :icon_file
  end
end
