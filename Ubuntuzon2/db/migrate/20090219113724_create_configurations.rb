class CreateConfigurations < ActiveRecord::Migration
  def self.up
    create_table :configurations do |t|
      t.integer :user_id
      t.integer :package_id
      t.float :rating

      t.timestamps
    end
  end

  def self.down
    drop_table :configurations
  end
end
