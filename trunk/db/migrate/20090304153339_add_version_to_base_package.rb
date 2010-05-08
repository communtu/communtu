class AddVersionToBasePackage < ActiveRecord::Migration
  def self.up
    add_column :base_packages, :version, :string
  end

  def self.down
    remove_column :base_packages, :version
  end
end
