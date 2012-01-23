class AddToLivecd < ActiveRecord::Migration
  def self.up
    add_column :livecds, :short_log, :string
  end

  def self.down
    remove_column :livecds, :short_log
  end
end
