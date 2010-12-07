class AddTestedFlagToBasePackages < ActiveRecord::Migration
  def self.up
    add_column :base_packages, :tested, :boolean, :default => false
  end

  def self.down
    remove_column :base_packages, :tested
  end
end
