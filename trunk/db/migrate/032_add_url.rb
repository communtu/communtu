class AddUrl < ActiveRecord::Migration
  def self.up
    add_column :distributions, :url, :string
end
    
  def self.down
    remove_column :distributions, :url
  end
end
