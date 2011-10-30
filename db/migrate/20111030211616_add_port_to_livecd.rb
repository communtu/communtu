class AddPortToLivecd < ActiveRecord::Migration
  def self.up
    add_column :livecds, :port, :integer
  end

  def self.down
    remove_column :livecds, :port
  end
end
