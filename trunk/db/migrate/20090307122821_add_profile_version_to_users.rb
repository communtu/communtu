class AddProfileVersionToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :profile_version, :integer
    add_column :users, :profile_changed, :boolean, :default => false
  end

  def self.down
    remove_column :users, :profile_version
    remove_column :users, :profile_changed
  end
end
