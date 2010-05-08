class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.integer :role_id, :user_id, :null => false
      t.timestamps
    end
  end
 
  def self.down
    drop_table :permissions
    Role.find_by_rolename('administrator').destroy   
    User.find_by_login('admin').destroy   
  end
end