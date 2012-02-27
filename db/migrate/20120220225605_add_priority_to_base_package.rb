class AddPriorityToBasePackage < ActiveRecord::Migration
  def self.up
    add_column :base_packages, :priority, :integer
    p=Package.find_by_name("menu")
    p.priority = 100
    p.save
  end

  def self.down
    remove_column :base_packages, :priority
  end
end
