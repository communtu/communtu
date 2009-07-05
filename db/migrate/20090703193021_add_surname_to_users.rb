class AddSurnameToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :surname, :string, :limit => 30, :default => ""
    add_column :users, :firstname, :string, :limit => 30, :default => ""
  end

  def self.down
    remove_column :users, :surname
    remove_column :users, :firstname
  end
end
