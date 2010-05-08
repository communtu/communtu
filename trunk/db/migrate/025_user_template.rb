class UserTemplate < ActiveRecord::Migration
  def self.up
    add_column :users, :template_id, :integer
end
    
  def self.down
    remove_column :users, :template_id
  end
end
