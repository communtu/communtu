class AddPackageUrl < ActiveRecord::Migration
  def self.up
      add_column :base_packages, :urls, :text
  end

  def self.down
      remove_column :base_packages, :urls
  end
end
