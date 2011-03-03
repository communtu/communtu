class AddDownloadedToLivecds < ActiveRecord::Migration
  def self.up
    add_column :livecds, :downloaded, :int, :default => 0
  end

  def self.down
    remove_column :livecds, :downloaded
  end
end
