class AddOutdatedToPackageDistr < ActiveRecord::Migration
  def self.up
    add_column :package_distrs, :outdated, :boolean, :default => :false
    add_column :package_distrs_architectures, :outdated, :boolean, :default => :false
  end

  def self.down
    remove_column :package_distrs, :outdated
    remove_column :package_distrs_architectures, :outdated
  end
end
