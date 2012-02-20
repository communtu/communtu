class AddPriorityToBasePackage < ActiveRecord::Migration
  def self.up
    add_column :base_packages, :priority, :integer
  end

  def self.down
    remove_column :base_packages, :priority
  end
end
