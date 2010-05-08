class AddPackageFileToRepository < ActiveRecord::Migration
  def self.up
    add_column :repositories, :package_file, :text
  end

  def self.down
    remove_column :repositories, :package_file
  end
end
