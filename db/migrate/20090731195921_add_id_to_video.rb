class AddIdToVideo < ActiveRecord::Migration
  def self.up
    add_column :videos, :description_tid, :integer
    add_column :videos, :url_tid, :integer
  end

  def self.down
    remove_column :videos, :description_tid
    remove_column :videos, :url_tid
  end
end
