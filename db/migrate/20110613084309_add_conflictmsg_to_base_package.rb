class AddConflictmsgToBasePackage < ActiveRecord::Migration
  def self.up
    add_column :base_packages, :conflict_msg, :string
  end

  def self.down
    remove_column :base_packages, :conflict_msg
  end
end
