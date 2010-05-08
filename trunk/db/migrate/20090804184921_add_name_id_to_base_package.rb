class AddNameIdToBasePackage < ActiveRecord::Migration
  def self.up
    add_column :base_packages, :name_tid, :integer
  end

  def self.down
    remove_column :base_packages, :name_tid
  end
end
