class AddToCategory < ActiveRecord::Migration
  def self.up
    add_column :categories, :link, :string
  end

  def self.down
    remove_column :categories, :link
  end
end
