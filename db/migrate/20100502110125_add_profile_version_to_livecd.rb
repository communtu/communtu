class AddProfileVersionToLivecd < ActiveRecord::Migration
  def self.up
    add_column :livecds, :profile_version, :integer
  end

  def self.down
    remove_column :livecds, :profile_version
  end
end
