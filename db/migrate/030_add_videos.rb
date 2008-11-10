class AddVideos < ActiveRecord::Migration
  def self.up
    add_column :base_packages, :videos, :text
end
    
  def self.down
    remove_column :base_packages, :videos
  end
end
