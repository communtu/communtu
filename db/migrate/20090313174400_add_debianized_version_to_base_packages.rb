class AddDebianizedVersionToBasePackages < ActiveRecord::Migration
  def self.up
    add_column :base_packages, :debianized_version, :string
  end

  def self.down
    remove_column :base_packages, :debianized_version
  end
end
