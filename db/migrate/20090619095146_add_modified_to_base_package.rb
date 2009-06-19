class AddModifiedToBasePackage < ActiveRecord::Migration
  def self.up
    add_column :base_packages, :modified, :boolean, :default => false
    add_column :base_packages, :debianizing, :boolean, :default => false
    add_column :base_packages, :deb_error, :boolean, :default => false
  end

  def self.down
    remove_column :base_packages, :modified
    remove_column :base_packages, :debianizing
    remove_column :base_packages, :deb_error
  end
end
