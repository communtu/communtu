class AddIdToCategory < ActiveRecord::Migration
  def self.up
    add_column :categories, :name_tid, :integer
    add_column :categories, :description_tid, :integer
    add_column :categories, :link_tid, :integer
  end

  def self.down
    remove_column :categories, :name_tid
    remove_column :categories, :description_tid
    remove_column :categories, :link_tid
  end
end
