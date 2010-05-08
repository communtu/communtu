class AddToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :anonymous, :boolean, :default => false
  end

  def self.down
    remove_column :users, :anonymous
  end
end
