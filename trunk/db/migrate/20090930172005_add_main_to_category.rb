class AddMainToCategory < ActiveRecord::Migration
  def self.up
    add_column :categories, :main, :boolean, :default => false
  end

  def self.down
    remove_column :categories, :main
  end
end
