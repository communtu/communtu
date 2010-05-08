class CreateUserlogs < ActiveRecord::Migration
  def self.up
    create_table :userlogs, :force => true do |t|
    t.column :user_id, :integer
    t.column :created_at, :datetime, :null => false
    t.column :refferer, :string, :limit => 240, :default => ""
    end
  end

  def self.down
    drop_table :userlogs
  end
end
